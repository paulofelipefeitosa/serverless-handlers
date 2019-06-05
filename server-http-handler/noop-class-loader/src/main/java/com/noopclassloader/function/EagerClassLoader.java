package com.noopclassloader.function;

import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.util.Map;
import java.util.Set;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.ConcurrentSkipListSet;
import java.util.jar.JarEntry;
import java.util.jar.JarFile;

public class EagerClassLoader extends ClassLoader {

    private JarFile jarFile;
    private final int bufferSize = 5000;
    byte[] buffer = new byte[this.bufferSize];
    private Map<String, Class<?>> mapClass;
    private Set<Long> threads;
    private Map<String, LoadStats> stats;

    public EagerClassLoader(String jarFilePath) throws IOException {
        this.jarFile = new JarFile(jarFilePath);
        this.mapClass = new ConcurrentHashMap<String, Class<?>>();
        this.stats = new ConcurrentHashMap<String, LoadStats>();
        this.threads = new ConcurrentSkipListSet<Long>();
    }

    public String loadJarClasses() throws IOException {
        long startTime = System.nanoTime();
        try {
            this.jarFile
                .stream()
//                .parallel()
                .filter(e -> (!e.isDirectory()
                            && e.getName().startsWith("generated")
                            && e.getName().endsWith(".class")))
                .allMatch(e -> {
                        try {
                            String className =
                                    e.getName().replaceAll("\\.class", "").replaceAll("/", ".");
                            loadClass(className, false);
                            return true;
                        } catch (ClassNotFoundException e1) {
                            e1.printStackTrace();
                            return true;
                        }
                });
            return "Total Load Time: " + (System.nanoTime() - startTime) + System.lineSeparator()
                    + this.stats.values().stream()
                            .reduce(new LoadStats(0L, 0L, 0L), (a, e) -> a.add(e)).toString()
                    + System.lineSeparator() + "Running Threads: " + this.threads.size()
                    + System.lineSeparator() + "Loaded Classes: " + this.mapClass.size();
        } finally {
            this.jarFile.close();
        }
    }

    @Override
    protected Class<?> loadClass(String name, boolean resolve) throws ClassNotFoundException {
        this.threads.add(Thread.currentThread().getId());
        Class<?> c = this.mapClass.get(name);
        if (c != null) {
            return c;
        }
        JarEntry entry = this.jarFile.getJarEntry(name.replaceAll("\\.", "/") + ".class");
        if (entry != null) {
            try (InputStream is = this.jarFile.getInputStream(entry)) {
                long startReader = System.nanoTime();

                byte[] byteArr = toByteArray(is);
                c = defineClass(name, byteArr, 0, byteArr.length);

                long startInterpreter = System.nanoTime();
                try {
                    c.newInstance();
                } catch (Throwable e) {
                }
                long end = System.nanoTime();

                this.stats.put(name, new LoadStats(startInterpreter - startReader,
                        end - startInterpreter, byteArr.length));

                this.mapClass.put(name, c);
                return c;
            } catch (IOException e) {
                throw new ClassNotFoundException(e.toString());
            }
        } else {
            c = getClass().getClassLoader().loadClass(name);
            return c;
        }
    }

    private byte[] toByteArray(InputStream inputStream) throws IOException {
        ByteArrayOutputStream out = new ByteArrayOutputStream(this.bufferSize);
        int read;
        while ((read = inputStream.read(buffer, 0, buffer.length)) != -1) {
            out.write(buffer, 0, read);
        }
        out.flush();
        return out.toByteArray();
    }

}
