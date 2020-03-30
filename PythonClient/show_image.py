import argparse
import cv2
from PIL import Image




def show_image(args):
    img=cv2.imread(args.imagepath,1)
    img2 = Image.fromarray(img, 'RGB')
    img2.show()






def main():
    argparser = argparse.ArgumentParser(description=__doc__)
    # Option to set the URL of the image which needs to open
    argparser.add_argument(
        '-i', '--imagepath',
        metavar='I',
        default=None,
        help='Path of the image to show.')
    
    args = argparser.parse_args()
    
    show_image(args)


if __name__=='__main__':
    try:
        main()
    except KeyboardInterrupt:
        print('\nCancelled by user. Bye!')
