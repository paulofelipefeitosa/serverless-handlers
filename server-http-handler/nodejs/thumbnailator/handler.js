const sharp = require('sharp')
const scale = parseFloat(process.env.scale)
const image_path = process.env.image_path
const image = sharp(image_path)

function resizer(scale, image) {
	return image
		.metadata()
		.then((metadata) => {
			return image
				.resize(metadata.width * scale, metadata.height * scale)
				.toBuffer()
				//.toFile('output.jpg')
				//.then(data => {})	
		})
}

function handle(getTimestamp, req, res) {
	console.log('T4: ' + getTimestamp())
	resizer(scale, image)
		.then((info) => {
			res.writeHead(200);
		})
		.catch((error) => {
			res.writeHead(500);
			res.write(error)
		})
	console.log('T6: ' + getTimestamp())
	return res
}

module.exports.handle = handle;