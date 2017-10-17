## Simple performance comparison between different HTTP download methods

See also [this thread](https://stackoverflow.com/questions/46765393/high-cpu-utilization-when-downloading-files) on Stack Overflow.

Downloading a 100 MB file with curl and the four methods used in this program on a Cubieboard (a low-end single-core ARM SoC) yields the following results:

| Download method  | Duration (seconds) |
| ------------- | ------------- |
| curl  | 9  |
| download_tcp  | 12  |
| dowload_http  | 15  |
| download_ibrowse  | 15  |
| download_hackney  | 19  |


Which means that, while curl manages to fully utilize the available bandwidth provided by the 100 MBit network interface, the four methods implemented here are not quite as efficient.

If you find that one of the four methods can be improved somehow, feel free to open an issue or pull request.
