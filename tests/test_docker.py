import pytest

@pytest.mark.pytorch
def test_pytorch_image():
    import torch
    print(torch.__version__)

@pytest.mark.tensorflow
def test_tensorflow_image():
    import tensorflow as tf 
    print(tf.__version__)

@pytest.mark.deepspeed
def test_deepspeed_image():
    import deepspeed
    print(deepspeed.__version__)