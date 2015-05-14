URI content tracker
===================

Tracks changes to specified URI.

Requires
========

   $ cpanm Web::Scraper String::Similarity

Usage
=====

   $ ./scraper.pl http://blogs.perl.org/ 3600 0.8

3600 -- time in seconds between checks, 0.8 -- similarity factor limit (1 is identical).

Upon retrieving the content is stored into data folder for later comparasion.

