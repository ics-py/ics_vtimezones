# ics.py vTimezone Data
This project independently packages the timezone data required by [`ics.py`](https://github.com/C4ptainCrunch/ics.py).
It includes the [Olson / IANA timezone Database](https://www.iana.org/time-zones) converted to [iCalender vTimezone](https://icalendar.org/iCalendar-RFC-5545/3-6-5-time-zone-component.html) files by [vzic](https://github.com/libical/vzic/)
and the [Unicode CLDR](http://cldr.unicode.org/index) mapping of [Windows timezone names](http://cldr.unicode.org/development/development-process/design-proposals/extended-windows-olson-zid-mapping) to the Olson identifiers.

Having a separate project from ics.py allows regular releases when the timezone data changes
(which is not as seldom as you might think) without having to do a new release of `ics.py`.
Similar to `pytz`, this project follows the `YYYY.minor` [calendar versioning](https://calver.org/) scheme representing the periodic updates of its data,
while `ics.py` uses [semantic versioning](https://semver.org/) to allow ensuring compatibility with its more gradually evolving code-base.

## License
The source code of the project itself and the IANA time zone database are in the public domain,
while the Unicode CLDR Windows timezone name mapping file is under the [Unicode, inc. license agreement for data files and software](https://www.unicode.org/license.html), having the following copyright notice:
> Copyright © 1991-2013 Unicode, Inc.
> CLDR data files are interpreted according to the LDML specification (http://unicode.org/reports/tr35/)
> For terms of use, see http://www.unicode.org/copyright.html