package com.noopclassloader.function;

public class LoadStats {
    long readTime;
    long compTime;
    long size;

    public LoadStats(long readTime, long compTime, long size) {
        this.readTime = readTime;
        this.compTime = compTime;
        this.size = size;
    }

    public LoadStats add(LoadStats e) {
        this.readTime += e.readTime;
        this.compTime += e.compTime;
        this.size += e.size;
        return this;
    }

    @Override
    public String toString() {
        return "ReadTime: " + readTime + System.lineSeparator() + "CompTime: " + compTime
                + System.lineSeparator() + "TotSize: " + size;
    }

}
