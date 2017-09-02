#!/usr/bin/env python3
from PIL import Image, ImageFont, ImageDraw
import configparser
import os
import sys


def make_splash(width, height, filename, landscape=False, text="", config_file=None, center=False):
    print("Creating ({}x{}) splashscreen {}".format(width, height, os.path.basename(filename)))

    config = configparser.ConfigParser()
    if config_file is not None:
        config.read(config_file)

    im = Image.new('RGB', (width, height), color=config.get('background', 'color', fallback=0))
    draw = ImageDraw.Draw(im)

    spacing = width / 100 * float(config.get('logo', 'spacing', fallback='0'))

    font_size = int(width / 13)
    logo_size = int(width / 10)
    text_size = int(width / 30)

    name = config.get('name', 'text', fallback='postmarketOS')
    logo = config.get('logo', 'text', fallback='♻')

    name_font = check_font(config, 'name')
    logo_font = check_font(config, 'logo')
    text_font = check_font(config, 'text')

    name_font = ImageFont.truetype(name_font, font_size)
    logo_font = ImageFont.truetype(logo_font, logo_size)
    text_font = ImageFont.truetype(text_font, text_size)

    name_width, name_height = draw.textsize(name, font=name_font)
    logo_width, logo_height = draw.textsize(logo, font=logo_font)

    draw.text(((width - (name_width + logo_width)) / 2 + logo_width + spacing, (height - name_height) / 2), name,
              config.get('name', 'color', fallback='#ffffff'), font=name_font)

    draw.text(((width - (name_width + logo_width + spacing)) / 2, (height - name_height) / 2), logo,
              config.get('logo', 'color', fallback='#009900'),
              font=logo_font)

    if text != "" and text is not None:

        text_top = (height / 2) + name_height
        _, line_height = draw.textsize('A', font=text_font)
        text_left = width * 0.05
        for hardcoded_line in text.replace("\\n", "\n").splitlines():
            lines = visual_split(hardcoded_line, text_font, width * 0.9)
            for line in lines:

                if center:
                    line_width, _ = draw.textsize(line, font=text_font)
                    text_left = (width / 2) - (line_width / 2)

                draw.text((text_left, text_top), line, fill=config.get('text', 'color', fallback='#cccccc'),
                          font=text_font)
                text_top += line_height + (text_size * 0.4)

    del draw
    im.save(filename, format='PPM')


def check_font(config, section):
    fallback_font = '/usr/share/fonts/ttf-dejavu/DejaVuSans.ttf'
    font_file = config.get(section, 'font', fallback=fallback_font)
    if not os.path.isfile(font_file):
        print("Font file '{}' does not exist ({}).".format(font_file, section), file=sys.stderr)
        exit(1)
    return font_file


def visual_split(text, font, width, response_type='list'):
    font = font
    words = text.split()

    word_lengths = [(word, font.getsize(word)[0]) for word in words]
    space_length = font.getsize(' ')[0]

    lines = ['']
    line_length = 0

    for word, length in word_lengths:

        if line_length + length <= width:
            lines[-1] = '{line}{word} '.format(line=lines[-1], word=word)
            line_length += length + space_length
        else:
            lines.append('{word} '.format(word=word))
            line_length = length + space_length

    if response_type == 'list':
        return [line.strip() for line in lines]
    elif response_type == 'str':
        return '\n'.join(line.strip() for line in lines)
    else:
        raise ValueError('Invalid response type. Valid values are "list" and "str".')


if __name__ == '__main__':
    import argparse

    parser = argparse.ArgumentParser(description="Splash generator for postmarketOS")
    parser.add_argument('width', type=int)
    parser.add_argument('height', type=int)
    parser.add_argument('filename')
    parser.add_argument('--landscape', action='store_true', help='Rotate splash screen for landscape device')
    parser.add_argument('--text', type=str, help='Additional text for the splash screen')
    parser.add_argument('--center', action='store_true', help='Center text')
    parser.add_argument('--config', type=str, help='Config file for splash screen style')
    args = parser.parse_args()

    make_splash(args.width, args.height, args.filename, args.landscape, args.text, args.config, args.center)
