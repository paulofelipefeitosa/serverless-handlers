#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#include "jvmti.h"

static void check_jvmti_errors(jvmtiEnv *jvmti, jvmtiError errnum, const char *str);
static void trace(jvmtiEnv *jvmti_env, const char* fmt, ...);

static jvmtiEnv *jvmti;
static jrawMonitorID vmtrace_lock;
static struct timespec tms;
static FILE* out;

static long long getCurrentTimestamp() {
    if(clock_gettime(CLOCK_MONOTONIC, &tms)) {
        return -1;
    }
    long long nanosecs = tms.tv_sec * 1000000000;
    nanosecs += tms.tv_nsec;
    return nanosecs;
}

static void trace(jvmtiEnv *jvmti_env, const char* fmt, ...) {
    (*jvmti_env)->RawMonitorEnter(jvmti_env, vmtrace_lock);

    jlong current_time;
    (*jvmti_env)->GetTime(jvmti_env, &current_time);

    char buf[1024];
    va_list args;
    va_start(args, fmt);
    vsprintf(buf, fmt, args);
    va_end(args);

    fprintf(out, "[%lld] %s\n", current_time, buf);

    (*jvmti_env)->RawMonitorExit(jvmti_env, vmtrace_lock);
}

static char* fix_class_name(char* class_name) {
    class_name[strlen(class_name) - 1] = 0;
    return class_name + 1;
}

void JNICALL VMStart(jvmtiEnv *jvmti_env, 
        JNIEnv* jni_env) {
    trace(jvmti_env, "VM started");
}

void JNICALL VMInit(jvmtiEnv *jvmti_env, 
        JNIEnv* jni_env, 
        jthread thread) {
    trace(jvmti_env, "VM initialized");
}

void JNICALL VMDeath(jvmtiEnv *jvmti_env, 
        JNIEnv* jni_env) {
    trace(jvmti_env, "VM destroyed");
}

static void setEventNotification(jvmtiEnv* env,
            jvmtiEventMode mode,
            jvmtiEvent event_type) {
    jvmtiError error = (*env)->SetEventNotificationMode(env, mode, event_type, (jthread) NULL);
    check_jvmti_errors(env, error, "Unable to set the event notification mode");
}

static char checkPattern(char *text, 
            int l, 
            char *pattern) {
    int i, n = strlen(pattern);
    for(i = 0; i < n && pattern[i] == text[i + l];i++);
    return i == n;
}

static void traceMainMethodEvent(jvmtiEnv *jvmti, 
            jmethodID *method,
            const char* eventType) {
    char *method_name;
    char *signature_ptr;
    char *generic_ptr;

    jvmtiError error = (*jvmti)->GetMethodName(jvmti, *method, &method_name, &signature_ptr, &generic_ptr);
    check_jvmti_errors(jvmti, error, "Unable to get the method name");

    int size_method_name = strlen(method_name);
    char pattern[5] = {'m', 'a', 'i', 'n', '\0'};
    if(size_method_name == 4) {
        if(checkPattern(method_name, 0, pattern)) {
            trace(jvmti, "%s method: %s", eventType, method_name);
        }
    }

    (*jvmti)->Deallocate(jvmti, method_name);
    (*jvmti)->Deallocate(jvmti, signature_ptr);
    (*jvmti)->Deallocate(jvmti, generic_ptr);
}

void JNICALL MethodEntry(jvmtiEnv *jvmti, 
            JNIEnv *jni, 
            jthread thread, 
            jmethodID method) {
    traceMainMethodEvent(jvmti, &method, "Entered in");
}

void JNICALL MethodExit(jvmtiEnv *jvmti_env,
            JNIEnv* jni_env,
            jthread thread,
            jmethodID method,
            jboolean was_popped_by_exception,
            jvalue return_value) {
    traceMainMethodEvent(jvmti, &method, "Exit from");
}

JNIEXPORT jint JNICALL Agent_OnLoad(JavaVM *jvm, 
            char *options, 
            void *reserved) {
    long long start_time = getCurrentTimestamp();

    if (options == NULL || !options[0]) {
        out = stdout;
    } else if ((out = fopen(options, "w")) == NULL) {
        fprintf(stderr, "Cannot open output file: %s\n", options);
        return 1;
    }

    fprintf(out, "[%lld] JVMTI started\n", start_time);

    jvmtiError error;
    jint res;
    jvmtiEventCallbacks callbacks;
    jvmtiCapabilities capa;

    // Get the JVMTI environment
    res = (*jvm)->GetEnv(jvm, (void **) &jvmti, JVMTI_VERSION_1_0);
    if (res != JNI_OK || jvmti == NULL) {
        fprintf(stderr, "Unable to get access to JVMTI version 1.0");
    }
    //trace(jvmti, "VMTrace started");
    
    (void) memset(&capa, 0, sizeof(jvmtiCapabilities));

    // Let's initialize the capabilities
    capa.can_generate_method_entry_events = 1;
    capa.can_generate_method_exit_events = 1;
    error = (*jvmti)->AddCapabilities(jvmti, &capa);
    check_jvmti_errors(jvmti, error, "Unable to add the required capabilities");

    // Setup event notification
    setEventNotification(jvmti, JVMTI_ENABLE, JVMTI_EVENT_VM_START);
    setEventNotification(jvmti, JVMTI_ENABLE, JVMTI_EVENT_VM_INIT);
    setEventNotification(jvmti, JVMTI_ENABLE, JVMTI_EVENT_VM_DEATH);
    setEventNotification(jvmti, JVMTI_ENABLE, JVMTI_EVENT_METHOD_ENTRY);
    setEventNotification(jvmti, JVMTI_ENABLE, JVMTI_EVENT_METHOD_EXIT);

    // Setup the callbacks
    (void) memset(&callbacks, 0, sizeof(callbacks));
    callbacks.VMStart = VMStart;
    callbacks.VMInit = VMInit;
    callbacks.VMDeath = VMDeath;
    callbacks.MethodEntry = MethodEntry;
    callbacks.MethodExit = MethodExit;
    error = (*jvmti)->SetEventCallbacks(jvmti, &callbacks, (jint) sizeof(callbacks));
    check_jvmti_errors(jvmti, error, "Unable to set event callbacks");

    // Get the raw monitor
    error = (*jvmti)->CreateRawMonitor(jvmti, "JVMTI agent data", &vmtrace_lock);
    check_jvmti_errors(jvmti, error, "Unable to create a Raw monitor");

    return JNI_OK;
}

static void check_jvmti_errors(jvmtiEnv *jvmti, 
            jvmtiError errnum, 
            const char *str) {
    if (errnum != JVMTI_ERROR_NONE) {
        char *errnum_str;
        errnum_str = NULL;
        (void) (*jvmti)->GetErrorName(jvmti, errnum, &errnum_str);
        fprintf(stderr, "ERROR: JVMTI: [%d] %s - %s\n", errnum, (errnum_str == NULL ? "Unknown": errnum_str), (str == NULL? "" : str));
    }
}

JNIEXPORT void JNICALL Agent_OnUnload(JavaVM *vm) {
    if (out != NULL && out != stderr) {
        fclose(out);
    }
}