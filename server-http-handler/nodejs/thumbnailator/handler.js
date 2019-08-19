const sharp = require('sharp')
const fs = require('fs')
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
		})
}

function handle(req, res) {
	return resizer(scale, image)
		.then(() => {
			res.writeHead(200);
			return res
		})
		.catch((error) => {
			res.writeHead(500);
			res.write(error)
			return res
		})
}

module.exports.handle = handle;