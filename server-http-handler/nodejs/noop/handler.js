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
	console.log('T4: ' + getNanoRealTime())
	res.writeHead(200);
	console.log('T6: ' + getNanoRealTime())
	res.end()
}).listen(port, ip)

console.log('EFM: ' + getNanoRealTime())