const handler = require('./handler.js')
const process = require('process')
console.log('EIM: ' + getNanoRealTime())

function getNanoRealTime() {
	timestamps = process.hrtime()
	return (timestamps[0] * 1e9) + timestamps[1]
}

const http = require('http')
const port = 9000
const ip = 'localhost'

const server = http.createServer((req, res) => {
	const isWarmReq = req.headers['x-warm-request'] == "true";
	if (!isWarmReq) {
		console.log('T4: ' + getNanoRealTime())
	}
	handler.handle(req, res)
		.then((res) => {
			if (!isWarmReq) {
				console.log('T6: ' + getNanoRealTime())
			}
			res.end()
		})
}).listen(port, ip)

console.log('EFM: ' + getNanoRealTime())