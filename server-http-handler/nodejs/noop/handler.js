module.exports = {
	handle: function(getTimestamp, req, res) {
		console.log('T4: ' + getTimestamp())
		res.writeHead(200);
		console.log('T6: ' + getTimestamp())
		return res
	}
}