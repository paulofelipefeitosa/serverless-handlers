from utils.http_entities import Response
from PIL import Image
import os

scale = float(os.environ['scale'])
image_path = os.environ['image_path']
image = Image.open(image_path)

def handle(request):
	response = Response()
	try:
		image.resize((int(image.width * scale), int(image.height * scale)), Image.BILINEAR)
		if request.get_header('x-save-image'):
			image.save('output.jpg')
		response.set_status_code(200)
	except Exception as e:
		response.set_status_code(500)
		response.set_body(str(e) + '\n')

	return response