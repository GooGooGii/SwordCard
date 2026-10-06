"""Import a generated 2x2 turnaround into the existing 3D projection pipeline.

This extracts views, preserves RGBA artwork, and standardizes camera framing;
it does not repaint the character. Original sheets remain untouched.
"""
import argparse
from pathlib import Path
from PIL import Image


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('sheet', type=Path)
    parser.add_argument('output', type=Path)
    args = parser.parse_args()
    source = Image.open(args.sheet).convert('RGBA')
    w, h = source.size
    args.output.mkdir(parents=True, exist_ok=True)
    cells = [('front', (0, 0, w // 2, h // 2)),
             ('left', (w // 2, 0, w, h // 2)),
             ('back', (0, h // 2, w // 2, h)),
             ('right', (w // 2, h // 2, w, h))]
    for name, box in cells:
        cell = source.crop(box)
        bbox = cell.getchannel('A').point(lambda value: 255 if value > 127 else 0).getbbox()
        if not bbox:
            raise ValueError(f'{name} has no opaque figure')
        figure = cell.crop(bbox)
        ratio = 896 / figure.height
        size = (round(figure.width * ratio), 896)
        if size[0] > 1000:
            raise ValueError(f'{name} figure exceeds 3D camera framing')
        frame = Image.new('RGBA', (1024, 1024), (255, 255, 255, 0))
        frame.alpha_composite(figure.resize(size, Image.Resampling.LANCZOS), ((1024 - size[0]) // 2, 64))
        frame.save(args.output / f'{name}_rgba.png')
        white = Image.new('RGBA', frame.size, 'white')
        white.alpha_composite(frame)
        white.convert('RGB').save(args.output / f'{name}.png')
        print(name, 'figure', size, 'frame', frame.size)


if __name__ == '__main__':
    main()
