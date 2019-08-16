const sharp = require('sharp')
const scale = parseFloat(process.env.scale)
const image_path = process.env.image_path
const image = sharp(image_path)

function resizer(size, image) {
    try {
		size.then((size) => {
			image
			.resize(size.width, size.height)
			.toBuffer()
			//.toFile('output.jpg')
			//.then(data => {})	
		})
    } catch (error) {
    	throw new Error(error)
    }
}

function handle(getTimestamp, req, res) {
	console.log('T4: ' + getTimestamp())
	const new_size = image
		.metadata()
		.then((metadata) => {
			return {width: metadata.width * scale, height: metadata.height * scale}
		})
	resizer(new_size, image)
		.then(() => {
			res.writeHead(200);
			console.log('T6: ' + getTimestamp())
			return res
		})
		.catch((error) => {
			res.writeHead(500);
			res.write(error)
			return res
		})
}

module.exports.handle = handle;