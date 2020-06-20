ics.py vTimezone Data
=====================

This project independently packages the timezone data required by ics.py.
It includes the Olson Database converted to iCalender vTimezone files by vzic and the CLDR mapping of Windows timezone names to the Olson identifiers.
The source code of the project itself is in the public domain, while the data files collected from the mentioned projects follow their respective licences.

Having a separate project from ics.py allows regular releases when the timezone data changes (which is not as seldom as you might think) without having to do a new release of ics.py.
Similar to pytz, this project follows the YYYY.minor calendar versioning scheme representing the periodic updates of its data, while ics.py uses semantic versioning to allow ensuring compatibility with its more gradually evolving code-base.
