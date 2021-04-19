var showdown = require('showdown');
var fs = require('fs');
var converter = new showdown.Converter();

function handle(req, res) {
	var text = fs.readFileSync('./Open-README.md', 'utf-8').toString();
	html = converter.makeHtml(text);
	res.writeHead(200);
	res.write(html.substr(0, 10) + '\n');
	return new Promise(function(resolve, reject) { return resolve(res) })
}

module.exports.handle = handle;