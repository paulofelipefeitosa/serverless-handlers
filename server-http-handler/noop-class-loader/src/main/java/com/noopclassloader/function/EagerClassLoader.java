package com.noopclassloader.function;

import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.util.HashMap;
import java.util.Map;
import java.util.jar.JarEntry;
import java.util.jar.JarFile;

public class EagerClassLoader extends ClassLoader {

    private JarFile jarFile;
    private final int bufferSize = 5000;
    byte[] buffer = new byte[this.bufferSize];
    private Map<String, Class<?>> mapClass;
    private Map<String, LoadStats> stats;

    public EagerClassLoader(String jarFilePath) throws IOException {
        this.jarFile = new JarFile(jarFilePath);
        this.mapClass = new HashMap<String, Class<?>>();
        this.stats = new HashMap<String, LoadStats>();
    }

    public String loadJarClasses() throws IOException {
        long startTime = System.nanoTime();
        try {
            this.jarFile
                .stream()
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
                    + System.lineSeparator() + "Loaded Classes: " + this.stats.size();
        } finally {
            this.jarFile.close();
        }
    }

    @Override
    protected Class<?> loadClass(String name, boolean resolve) throws ClassNotFoundException {
        Class<?> c = this.mapClass.get(name);
        if (c != null) {
            return c;
        }
        JarEntry entry = this.jarFile.getJarEntry(name.replaceAll("\\.", "/") + ".class");
        if (entry != null) {
            try (InputStream is = this.jarFile.getInputStream(entry)) {
                long sr = System.nanoTime();
                byte[] byteArr = toByteArray(is);
                c = defineClass(name, byteArr, 0, byteArr.length);
                
                long si = System.nanoTime(), end = 0L;
                try {
                    if (name.startsWith("generated")) {
                        c.newInstance();
                        end = System.nanoTime();
                    } else {
                        end = System.nanoTime();
                    }
                } catch (Throwable e) {
                    e.printStackTrace();
                }

                this.stats.put(name, new LoadStats(si - sr, end - si, byteArr.length));
                
                this.mapClass.put(name, c);
                return c;
            } catch (IOException e) {
                throw new ClassNotFoundException(e.toString());
            }
        } else {
            long sr = System.nanoTime();
            c = getClass().getClassLoader().loadClass(name);
            long end = System.nanoTime();
            this.stats.put(name, new LoadStats(0, end - sr, 0));
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
