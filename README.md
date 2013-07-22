# tv-broadcast-maps

This repository contains GeoJSON files of broadcast contours for TV stations in the United States (all 50 states and DC).

Files are organized by state abbreviation and can be found inside the `json` folder.

Station data was gathered from the [FCC stations API](https://stations.fcc.gov/developer/). I've included the code I used to gather this data, so you can run it yourself--or suggest ways to make it better.

Many thanks to [wavded](https://github.com/wavded) for hosting his [ogr2ogr REST API](http://ogre.adc4gis.com/), which is used here quite often.

I've created a simple [website](http://adelevie.github.io/tv-broadcast-maps-website/www/index.html) that displays these maps, state-by-state. You can also browse its source code [here](https://github.com/adelevie/tv-broadcast-maps-website).

## License

Everything in the `json` folder is in the public domain. See `json/LICENSE`.

Scraper code that is not in the `json` folder is licensed by the MIT License. See `LICENSE`.