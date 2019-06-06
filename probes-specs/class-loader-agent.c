#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#include "jvmti.h"

static void check_jvmti_errors(jvmtiEnv *jvmti, jvmtiError errnum, const char *str);

static jvmtiEnv *jvmti;
static FILE* out;
static jrawMonitorID rawMonitorID;
static volatile char mainExit = 0;
static volatile long long int ldc_size_bm = 0LL; // total size of loaded classes before main exit
static volatile long long int ldc_size_am = 0LL; // total size of loaded classes after main exit
static volatile int total_ldc_bm = 0;
static volatile int total_ldc_am = 0;

static void trace_class(jvmtiEnv *jvmti_env, const jint size) {
    (*jvmti_env)->RawMonitorEnter(jvmti_env, rawMonitorID);

    if(mainExit == 0) {
        ldc_size_bm += size;
        total_ldc_bm++;
    } else {
        ldc_size_am += size;
        total_ldc_am++;
    }

    (*jvmti_env)->RawMonitorExit(jvmti_env, rawMonitorID);
}

static void print_stats(jvmtiEnv *jvmti_env) {
    (*jvmti_env)->RawMonitorEnter(jvmti_env, rawMonitorID);

    fprintf(out, "Before Main Exit TSoLC: %lld\n", ldc_size_bm);
    fprintf(out, "Before Main Exit ToLC: %d\n", total_ldc_bm);
    
    fprintf(out, "After Main Exit TSoLC: %lld\n", ldc_size_am);
    fprintf(out, "After Main Exit ToLC: %d\n", total_ldc_am);

    (*jvmti_env)->RawMonitorExit(jvmti_env, rawMonitorID);
}

void JNICALL VMDeath(jvmtiEnv *jvmti_env, 
        JNIEnv* jni_env) {
    print_stats(jvmti_env);
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
    trace_class(jvmti_env, class_data_len);
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
            const int set_value) {
    char *method_name;
    char *signature_ptr;
    char *generic_ptr;

    jvmtiError error = (*jvmti)->GetMethodName(jvmti, *method, &method_name, &signature_ptr, &generic_ptr);
    check_jvmti_errors(jvmti, error, "Unable to get the method name");

    int size_method_name = strlen(method_name);
    char pattern[5] = {'m', 'a', 'i', 'n', '\0'};
    if(size_method_name == 4) {
        if(checkPattern(method_name, 0, pattern)) {
            mainExit = set_value;
        }
    }

    (*jvmti)->Deallocate(jvmti, method_name);
    (*jvmti)->Deallocate(jvmti, signature_ptr);
    (*jvmti)->Deallocate(jvmti, generic_ptr);
}

void JNICALL MethodExit(jvmtiEnv *jvmti_env,
            JNIEnv* jni_env,
            jthread thread,
            jmethodID method,
            jboolean was_popped_by_exception,
            jvalue return_value) {
    traceMainMethodEvent(jvmti, &method, 1);
}

JNIEXPORT jint JNICALL Agent_OnLoad(JavaVM *jvm, 
            char *options, 
            void *reserved) {
    if (options == NULL || !options[0]) {
        out = stderr;
    } else if ((out = fopen(options, "a")) == NULL) {
        fprintf(stderr, "Cannot open output file: %s\n", options);
        return 1;
    }

    jvmtiError error;
    jint res;
    jvmtiEventCallbacks callbacks;
    jvmtiCapabilities capa;

    // Get the JVMTI environment
    res = (*jvm)->GetEnv(jvm, (void **) &jvmti, JVMTI_VERSION_1_0);
    if (res != JNI_OK || jvmti == NULL) {
        printf("Unable to get access to JVMTI version 1.0");
    }
    
    (void) memset(&capa, 0, sizeof(jvmtiCapabilities));

    // Let's initialize the capabilities
    capa.can_generate_all_class_hook_events = 1;
    capa.can_generate_method_exit_events = 1;
    error = (*jvmti)->AddCapabilities(jvmti, &capa);
    check_jvmti_errors(jvmti, error, "Unable to add the required capabilities");

    // Setup event notification
    setEventNotification(jvmti, JVMTI_ENABLE, JVMTI_EVENT_VM_DEATH);
    setEventNotification(jvmti, JVMTI_ENABLE, JVMTI_EVENT_CLASS_FILE_LOAD_HOOK);
    setEventNotification(jvmti, JVMTI_ENABLE, JVMTI_EVENT_METHOD_EXIT);

    // Setup the callbacks
    (void) memset(&callbacks, 0, sizeof(callbacks));
    callbacks.VMDeath = VMDeath;
    callbacks.ClassFileLoadHook = ClassFileLoadHook;
    callbacks.MethodExit = MethodExit;
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

        printf("ERROR: JVMTI: [%d] %s - %s\n", errnum, (errnum_str == NULL ? "Unknown": errnum_str), (str == NULL? "" : str));
    }
}

JNIEXPORT void JNICALL Agent_OnUnload(JavaVM *vm) {
    if (out != NULL && out != stderr) {
        fclose(out);
    }
}