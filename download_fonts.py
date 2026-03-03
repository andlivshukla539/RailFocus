import urllib.request
import os

os.makedirs('assets/fonts', exist_ok=True)

fonts = {
    'SpaceMono-Regular.ttf': 'https://github.com/google/fonts/raw/main/ofl/spacemono/SpaceMono-Regular.ttf',
    'SpaceMono-Bold.ttf': 'https://github.com/google/fonts/raw/main/ofl/spacemono/SpaceMono-Bold.ttf',
    'CormorantGaramond-Regular.ttf': 'https://github.com/google/fonts/raw/main/ofl/cormorantgaramond/CormorantGaramond-Regular.ttf',
    'CormorantGaramond-Bold.ttf': 'https://github.com/google/fonts/raw/main/ofl/cormorantgaramond/CormorantGaramond-Bold.ttf',
    'CormorantGaramond-Italic.ttf': 'https://github.com/google/fonts/raw/main/ofl/cormorantgaramond/CormorantGaramond-Italic.ttf',
    'Cinzel-Regular.ttf': 'https://github.com/google/fonts/raw/main/ofl/cinzel/Cinzel-Regular.ttf',
    'Cinzel-Bold.ttf': 'https://github.com/google/fonts/raw/main/ofl/cinzel/Cinzel-Bold.ttf',
}

for name, url in fonts.items():
    print(f"Downloading {name}...")
    try:
        urllib.request.urlretrieve(url, f'assets/fonts/{name}')
    except Exception as e:
        print(f"Failed {name}: {e}")
