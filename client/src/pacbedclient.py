import numpy as np
import PIL.Image
import json
import requests
import base64
import io


def query(image_array, host='localhost', port=8010):
    resp = requests.post(f"http://{host}:{port}/inference/", files={
        "file": ("pacbed.raw", bytes(image_array), "application/octet-stream"),
        "parameters": (None, json.dumps({
            "dtype": str(image_array.dtype),
            "width": image_array.shape[1],
            "height": image_array.shape[0],
            "physical_params": {
                "acceleration_voltage": 80000,
                "zone_axis": {"u": 0, "v": 0, "w": 1},
                "crystal_structure": "Rutile",
                "convergence_angle": 20,
            }
        }), "application/json"),
    }, )
    resp = resp.json()
    png_bytes = base64.b64decode(resp['validation'])
    bytes_io = io.BytesIO(png_bytes)

    pil_image = PIL.Image.open(bytes_io, formats=['PNG'])

    rgb = np.asarray(pil_image)
    resp['validation'] = rgb
    return resp


def arrayfromID(DM, id: int):
    image = DM.FindImageByID(id)
    return image.GetNumArray()


def imagefromresponse(DM, resp, namespace: str = 'pacbed'):
    rgb = resp['validation']
    r_ = DM.CreateImage(rgb[:, :, 0].copy())
    g_ = DM.CreateImage(rgb[:, :, 1].copy())
    b_ = DM.CreateImage(rgb[:, :, 2].copy())

    r_.SetName(f'{namespace}:viz_r')
    g_.SetName(f'{namespace}:viz_g')
    b_.SetName(f'{namespace}:viz_b')

    tags = r_.GetTagGroup()
    for key in ('thickness', 'mistilt', 'scale'):
        tags.SetTagAsFloat(key, resp[key])
    r_.ShowImage()
    g_.ShowImage()
    b_.ShowImage()