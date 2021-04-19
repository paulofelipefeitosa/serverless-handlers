function handle(req, res) {
	const call_id = 0;
	const end = 5248;
	const base = 'module_';
	const next_module_fp = base + (call_id + 1).toString();
	try {
		var next_mod = require('./src/' + next_module_fp);
		let ans = next_mod.func_call(call_id + 1, end);
		res.writeHead(200);
		res.write(ans.toString() + '\n');
	} catch (e) {
		res.writeHead(500);
		res.write(e.toString() + '\n');
	}
	return new Promise(function(resolve, reject) { return resolve(res) });
}

module.exports.handle = handle;