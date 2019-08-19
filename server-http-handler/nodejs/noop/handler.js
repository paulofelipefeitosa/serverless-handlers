function handle(req, res) {
	res.writeHead(200);
	return new Promise(function(resolve, reject) { return resolve(res) })
}

module.exports.handle = handle;