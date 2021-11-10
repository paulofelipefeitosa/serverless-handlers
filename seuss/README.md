# SEUSS Experiments

## How to execute an experiment

You will run the bash script `exp.sh` passing 6 arguments:
```sh
bash exp.sh <EXP> <ROUNDS> <FUNC_PROJ_PATH> <MAIN_FILEPATH> <CONTAINER_LOG_FILEPATH> <RESULTS_FILEPATH>
```
1. **EXP** - the number of executions/runs of SEUSS.
2. **ROUNDS** -  the number of requests that must be triggered in each SEUSS execution/
3. **FUNC_PROJ_PATH** - the function project directory in the host machine, the function project directory will be bind into the container as a volume. Example of path: `/home/paulofelipe/serverless-handlers/seuss/functions/noop`.
4. **MAIN_FILEPATH** - the SEUSS container absolute path to the function main file, please notice that this path should reflect the container path, then it should follows the pattern `/root/seuss/function/<function_main_filename>`. For example, the **MAIN_FILEPATH** for NOOP must be: `/root/seuss/function/index.js`.
5. **LOG_FILEPATH** - the file path where the SEUSS container logs will be stored inside the host machine.
6. **RESULTS_FILEPATH** - the file path where the results will be stored. This results file follows the same structure of the [Prebaking experiments Results Artifacts](https://github.com/paulofelipefeitosa/serverless-handlers#results-artifact).

## Pipeline

### exp.sh
The [exp.sh](https://github.com/paulofelipefeitosa/serverless-handlers/blob/master/seuss/exp.sh) component is responsible for executing each experiment. For each experiment it call the `run.sh` script.

### run.sh
The [run.sh](https://github.com/paulofelipefeitosa/serverless-handlers/blob/master/seuss/run.sh) script orchestrates the experiment individually. The orchestration includes four steps:

#### clean.sh
The [clean.sh](https://github.com/paulofelipefeitosa/serverless-handlers/blob/master/seuss/clean.sh) cleanup any previous execution leftover.

#### launch.sh
The [launch.sh](https://github.com/paulofelipefeitosa/serverless-handlers/blob/master/seuss/launch.sh) component spin-up a new SEUSS setup, and waits SEUSS platform to be up and running.

#### exec.sh
The [exec.sh](https://github.com/paulofelipefeitosa/serverless-handlers/blob/master/seuss/exec.sh) communicates with SEUSS, and request the triggering of new requests as specified by the **ROUNDS** argument. Please, be aware that the communication with SEUSS is [quite complex](https://github.com/paulofelipefeitosa/serverless-handlers/blob/master/seuss/exec.sh#L11), can be done only once per container, and can fail. This script waits for a SEUSS signal indicating that it received the request, there is a timeout in place to [check for failures](https://github.com/paulofelipefeitosa/serverless-handlers/blob/master/seuss/exec.sh#L26).

#### parse.sh
The [parsh.sh](https://github.com/paulofelipefeitosa/serverless-handlers/blob/master/seuss/parse.sh) script is called in the last phase to get the execution results, and translate it to the Prebaking Result Artifact format.
