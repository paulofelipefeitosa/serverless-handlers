#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#include "jvmti.h"

static void check_jvmti_errors(jvmtiEnv *jvmti, jvmtiError errnum, const char *str);
static void trace(jvmtiEnv *jvmti_env, const char* fmt, ...);

static FILE* out;
static jrawMonitorID rawMonitorID;
static struct timespec tms;

static long long getCurrentTimestamp() {
    if(clock_gettime(CLOCK_REALTIME, &tms)) {
        return -1;
    }
    long long nanosecs = tms.tv_sec * 1000000000;
    nanosecs += tms.tv_nsec;
    return nanosecs;
}

static void trace(jvmtiEnv *jvmti_env, const char* fmt, ...) {
    (*jvmti_env)->RawMonitorEnter(jvmti_env, rawMonitorID);

    long long current_time = getCurrentTimestamp();

    char buf[1024];
    va_list args;
    va_start(args, fmt);
    vsprintf(buf, fmt, args);
    va_end(args);

    fprintf(out, "[%lld] %s\n", current_time, buf);

    (*jvmti_env)->RawMonitorExit(jvmti_env, rawMonitorID);
}

static char* fix_class_name(char* class_name) {
    // Strip 'L' and ';' from class signature
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

/* Load class data file */
void JNICALL ClassFileLoadHook(jvmtiEnv *jvmti_env,
            JNIEnv* jni_env,
            jclass class_being_redefined,
            jobject loader,
            const char* name,
            jobject protection_domain,
            jint class_data_len,
            const unsigned char* class_data,
            jint* new_class_data_len,
            unsigned char** new_class_data) {
    trace(jvmti_env, "Loading class: %s", name);
}

/* When class is loaded (fields, methods and implemented interfaces) but no class code is executed yet */
void JNICALL ClassPrepare(jvmtiEnv *jvmti_env,
            JNIEnv* jni_env,
            jthread thread,
            jclass klass) {
    char* name;
    (*jvmti_env)->GetClassSignature(jvmti_env, klass, &name, NULL);
    trace(jvmti_env, "Class prepared: %s", fix_class_name(name));
    (*jvmti_env)->Deallocate(jvmti_env, name);
}

/* Compiling JVM internal code */
void JNICALL DynamicCodeGenerated(jvmtiEnv *jvmti_env,
            const char* name,
            const void* address,
            jint length) {
    trace(jvmti_env, "Dynamic code generated: %s", name);
}

void JNICALL CompiledMethodLoad(jvmtiEnv *jvmti_env,
            jmethodID method,
            jint code_size,
            const void* code_addr,
            jint map_length,
            const jvmtiAddrLocationMap* map,
            const void* compile_info) {
    jclass holder;
    char* holder_name;
    char* method_name;
    (*jvmti_env)->GetMethodName(jvmti_env, method, &method_name, NULL, NULL);
    (*jvmti_env)->GetMethodDeclaringClass(jvmti_env, method, &holder);
    (*jvmti_env)->GetClassSignature(jvmti_env, holder, &holder_name, NULL);
    trace(jvmti_env, "Method compiled: %s.%s", fix_class_name(holder_name), method_name);
    (*jvmti_env)->Deallocate(jvmti_env, method_name);
    (*jvmti_env)->Deallocate(jvmti_env, holder_name);
}

static void setEventNotification(jvmtiEnv* env,
            jvmtiEventMode mode,
            jvmtiEvent event_type) {
    jvmtiError error = (*env)->SetEventNotificationMode(env, mode, event_type, (jthread) NULL);
    check_jvmti_errors(env, error, "Unable to set the event notification mode");
}

JNIEXPORT jint JNICALL Agent_OnLoad(JavaVM *jvm, 
        char *options, 
        void *reserved) {
    long long start_time = getCurrentTimestamp();

    if (options == NULL || !options[0]) {
        out = stderr;
    } else if ((out = fopen(options, "a")) == NULL) {
        fprintf(stderr, "Cannot open output file: %s\n", options);
        return 1;
    }

    fprintf(out, "[%lld] JVMTI started\n", start_time);

    jvmtiEnv *jvmti;
    jvmtiError error;
    jint res;
    jvmtiEventCallbacks callbacks;
    jvmtiCapabilities capa;

    // Get the JVMTI environment
    res = (*jvm)->GetEnv(jvm, (void **) &jvmti, JVMTI_VERSION_1_0);
    if (res != JNI_OK || jvmti == NULL) {
        printf("Unable to get access to JVMTI version 1.0");
    }
    trace(jvmti, "VMTrace started");
    
    (void) memset(&capa, 0, sizeof(jvmtiCapabilities));

    // Let's initialize the capabilities
    capa.can_generate_all_class_hook_events = 1;
    capa.can_generate_compiled_method_load_events = 1;
    error = (*jvmti)->AddCapabilities(jvmti, &capa);
    check_jvmti_errors(jvmti, error, "Unable to add the required capabilities");

    // Setup event notification
    setEventNotification(jvmti, JVMTI_ENABLE, JVMTI_EVENT_VM_START);
    setEventNotification(jvmti, JVMTI_ENABLE, JVMTI_EVENT_VM_INIT);
    setEventNotification(jvmti, JVMTI_ENABLE, JVMTI_EVENT_VM_DEATH);
    setEventNotification(jvmti, JVMTI_ENABLE, JVMTI_EVENT_CLASS_FILE_LOAD_HOOK);
    setEventNotification(jvmti, JVMTI_ENABLE, JVMTI_EVENT_CLASS_PREPARE);
    setEventNotification(jvmti, JVMTI_ENABLE, JVMTI_EVENT_DYNAMIC_CODE_GENERATED);
    setEventNotification(jvmti, JVMTI_ENABLE, JVMTI_EVENT_COMPILED_METHOD_LOAD);

    // Setup the callbacks
    (void) memset(&callbacks, 0, sizeof(callbacks));
    callbacks.VMStart = VMStart;
    callbacks.VMInit = VMInit;
    callbacks.VMDeath = VMDeath;
    callbacks.ClassFileLoadHook = ClassFileLoadHook;
    callbacks.ClassPrepare = ClassPrepare;
    callbacks.DynamicCodeGenerated = DynamicCodeGenerated;
    callbacks.CompiledMethodLoad = CompiledMethodLoad;
    error = (*jvmti)->SetEventCallbacks(jvmti, &callbacks, (jint) sizeof(callbacks));
    check_jvmti_errors(jvmti, error, "Unable to set event callbacks");

    // Get the raw monitor
    error = (*jvmti)->CreateRawMonitor(jvmti, "JVMTI agent data", &rawMonitorID);
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

        printf("ERROR: JVMTI: [%d] %s - %s", errnum, (errnum_str == NULL ? "Unknown": errnum_str), (str == NULL? "" : str));
    }
}

JNIEXPORT void JNICALL Agent_OnUnload(JavaVM *vm) {
    if (out != NULL && out != stderr) {
        fclose(out);
    }
}