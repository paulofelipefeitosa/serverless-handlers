function main(args) {
    const call_id = 0;
    const end = 5248;
    const base = 'module_';
    const next_module_fp = base + (call_id + 1).toString();
    try {
        var next_mod = require('./nodejsActionBase/big/src/' + next_module_fp);
        return next_mod.func_call(call_id + 1, end);
    } catch (e) {
        return {Call: call_id, Error: e.toString()};
    }
}