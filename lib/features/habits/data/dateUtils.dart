DateTime toUtcMidnight(DateTime d) => DateTime.utc(d.year, d.month, d.day);
DateTime monthStart(DateTime d) => DateTime.utc(d.year, d.month, 1);
DateTime monthEnd(DateTime d)   => DateTime.utc(d.year, d.month + 1, 0);
