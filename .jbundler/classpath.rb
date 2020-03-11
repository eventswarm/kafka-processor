JBUNDLER_CLASSPATH = []
JBUNDLER_CLASSPATH << '/Users/andyb/.m2/repository/org/slf4j/slf4j-simple/1.7.28/slf4j-simple-1.7.28.jar'
JBUNDLER_CLASSPATH << '/Users/andyb/.m2/repository/org/apache/kafka/kafka-streams/2.4.0/kafka-streams-2.4.0.jar'
JBUNDLER_CLASSPATH << '/Users/andyb/.m2/repository/org/apache/kafka/kafka-clients/2.4.0/kafka-clients-2.4.0.jar'
JBUNDLER_CLASSPATH << '/Users/andyb/.m2/repository/com/github/luben/zstd-jni/1.4.3-1/zstd-jni-1.4.3-1.jar'
JBUNDLER_CLASSPATH << '/Users/andyb/.m2/repository/org/lz4/lz4-java/1.6.0/lz4-java-1.6.0.jar'
JBUNDLER_CLASSPATH << '/Users/andyb/.m2/repository/org/xerial/snappy/snappy-java/1.1.7.3/snappy-java-1.1.7.3.jar'
JBUNDLER_CLASSPATH << '/Users/andyb/.m2/repository/org/apache/kafka/connect-json/2.4.0/connect-json-2.4.0.jar'
JBUNDLER_CLASSPATH << '/Users/andyb/.m2/repository/org/apache/kafka/connect-api/2.4.0/connect-api-2.4.0.jar'
JBUNDLER_CLASSPATH << '/Users/andyb/.m2/repository/javax/ws/rs/javax.ws.rs-api/2.1.1/javax.ws.rs-api-2.1.1.jar'
JBUNDLER_CLASSPATH << '/Users/andyb/.m2/repository/com/fasterxml/jackson/core/jackson-databind/2.10.0/jackson-databind-2.10.0.jar'
JBUNDLER_CLASSPATH << '/Users/andyb/.m2/repository/com/fasterxml/jackson/core/jackson-annotations/2.10.0/jackson-annotations-2.10.0.jar'
JBUNDLER_CLASSPATH << '/Users/andyb/.m2/repository/com/fasterxml/jackson/core/jackson-core/2.10.0/jackson-core-2.10.0.jar'
JBUNDLER_CLASSPATH << '/Users/andyb/.m2/repository/com/fasterxml/jackson/datatype/jackson-datatype-jdk8/2.10.0/jackson-datatype-jdk8-2.10.0.jar'
JBUNDLER_CLASSPATH << '/Users/andyb/.m2/repository/org/slf4j/slf4j-api/1.7.28/slf4j-api-1.7.28.jar'
JBUNDLER_CLASSPATH << '/Users/andyb/.m2/repository/org/rocksdb/rocksdbjni/5.18.3/rocksdbjni-5.18.3.jar'
JBUNDLER_CLASSPATH.freeze
JBUNDLER_CLASSPATH.each { |c| require c }
