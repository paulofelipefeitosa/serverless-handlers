# Prebaking Technique Experiments

This project contains the scripts and software used to perform and evaluate
experiments using the Prebaking Technique for Serverless Functions.

## Dependencies

This project requires the installation of the following dependencies, clicking on
them will redirect you to a resource explaining how to install each one:
* [**Golang >= 1.12**](https://golang.org/doc/install);
* [**Python 3 >= v3.5.2**](https://docs.python.org/3/using/unix.html#on-linux);
* [**Python 2 >= v2.7.12**](https://docs.python.org/2/using/unix.html#on-linux);
* [**Java 8**](https://docs.datastax.com/en/jdk-install/doc/jdk-install/installOpenJdkDeb.html);
* [**Rlang >= v4.0.0**](https://docs.rstudio.com/resources/install-r/);
* [**CRIU v2.6**](https://criu.org/Installation);
* [**Bpftrace v0.9**](https://github.com/iovisor/bpftrace/blob/master/INSTALL.md);
* [**Maven >= v3.3.9**](https://maven.apache.org/install.html).

Note that you might want to install these tools using easier approaches than 
those made available here.

## Load Generator Config

The Load Generator is the software component responsible
for the function process launch and workload injection in order to measure the 
start-up metrics.

Before executing an experiment, the `Load Generator` must be configured by creating
a json file containing the following properties:

* **Request** - the number of requests that should be injected into the function 
replica.

* **RequestSpec** - the specification of the request that will be injected into the
function replica, `Load Generator` supports `GET` and `POST` HTTP requests.

* **EnvVars** - a json array containing all the environment variables that should be
declared in order to successfully execute the function process. The env var must be
declared using the format `{Name}={Value}`. If your function 
does not require any environment variable, it can be ignored.

The following snippet shows an example of a `Load Generator Config`:
``` json
{
    "EnvVars": ["scale=0.1", "image_path=/home/user/image.jpg"],
    "Requests": 200,
    "RequestSpec": {
        "Method": "POST",
        "Path": "/",
        "Bodyfilepath": "/home/user/body.json",
    },
}
```

## Execution Script

We developed an automation script to be free from the burden of building the 
function source code, setting-up additional tracing scripts and perform multiple 
experiment executions. 

### Required Arguments

The script expects to receive the following arguments:
1. **Runtime** - the Runtime environment that will manage the function execution. 
We currently support **java**, **nodejs** and **python**.

2. **AppName** - the name of the application that will be evaluated. We currently
support **markdown**, **noop**, **thumbnailator** and **noop-class-loader**.

3. **NumberOfExecutions** - an integer value (greater than 0) that indicates how 
many times the script should repeat the experiment.

4. **StartupType** - the function startup mode. We currently support **no-criu** 
and **criu** modes.

5. **LoadGeneratorConfigPath** - the filepath to the `Load Generator Config`.

The below command shows the order that the script arguments should follow to
properly execute the script.
``` bash
bash run-experiment.sh {Runtime} {AppName} {NumberOfExecutions} {StartupType} {LoadGeneratorConfigPath}
```

### Optional Arguments

The script accepts optional arguments to configure the BPFTrace execution and
collect process-grain I/O statistics.

* `--executor_process_name={Name}` - the name of the process executing the function.
* `--iostats` - enable the tracing of I/O statistics.

Some optional arguments also can enable other types of executions, for instance:
1. The **Synthetic Function** experiment, which loads a predefined number of classes 
when invoked.
2. The **Prebaking-Warmup** experiment, which sends a request to warm the function 
source before the function process checkpoint.

* `--sf_jar_path={JarPath}` - the synthetic function jar path.
* `--warm_req` - enable warm up request before CRIU process checkpoint.

## Results Artifact

After each experiment execution, the `Load Generator` stores all collected metrics
into a CSV file, this file will contain the following columns:
1. **Metric** - the name of the collected metric.

2. **ExecID** - the experiment execution ID.

3. **ReqID** - the request ID which triggered the metric collection.

4. **Value** - the collected value for the target metric.
``` csv
Metric,ExecID,ReqID,Value
```

### Collected Metrics

For the very first request with `ReqID == 0`, we currently collect the 
following metrics:
1. **MainEntry** - the nanosecond's **timestamp** when the function process started 
executing the function initialization code.

2. **MainExit** - the nanosecond's timestamp when the function process finished 
the function initialization code execution.

3. **Ready2Serve** - the nanosecond's **timestamp** when the function process started 
executing the function business logic.

4. **RuntimeReadyTime** - the nanosecond's **time** the function process took to 
start executing the function business logic, since the launch of the function 
process.

5. **ServiceTime** - the nanosecond's **time** the function business logic took to
process the function client request.

6. **LatencyTime** - the nanosecond's **time** the function took to process the
function client request, since the launch of the function process.

For the remaining requests with `ReqID > 0`, as the initialization process is fully 
complete for the runtime and the function, we only collect the **ServiceTime**
and **LatencyTime** metrics. Please note that in this case, **LatencyTime** only
takes into account the time since the request was trigger by the `Load Generator`.

#### Synthetic Function Metrics

When performing the Synthetic Function experiment by setting the script argument 
`sf_jar_path`, the function collects the following additional metrics:

1. **LoadedClasses** - the **number** of loaded classes from the synthetic function.

2. **FindingClassesTime** - the nanosecond's **time** the runtime took to find the
classes inside the synthetic function jar.

3. **CompilingClassesTime** - the nanosecond's **time** the runtime took to compile
the synthetic function classes.

4. **LoadClassesTotalTime** - the nanosecond's **time** the runtime took to load
the synthetic function classes.

5. **LoadingClassesOverheadTime** - the introduced overhead to request the load
of all synthetic function classes. This overhead time unit is nanoseconds.

Please also note that these metrics only are collected for the very first request
 with `ReqID == 0`.
