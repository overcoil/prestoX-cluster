
# header as described from: https://docs.delta.io/latest/quick-start.html
import pyspark
from delta import *

builder = pyspark.sql.SparkSession.builder.appName("CreateUnmanagedTable_WithAdditions") \
    .config("spark.sql.extensions", "io.delta.sql.DeltaSparkSessionExtension") \
    .config("spark.sql.catalog.spark_catalog", "org.apache.spark.sql.delta.catalog.DeltaCatalog")

spark = configure_spark_with_delta_pip(builder).getOrCreate()

# 
# Translation of the Employee Academy tutorial's CreateUnmanagedTable.dbc
#
# This is a standalone program suitable for Pyspark (as opposed to the .dbc) which
#   runs on a cluster (either Databricks Cloud or local/standalone)
#
# Dependency:
#   1. The uszips.csv sample dataset from the tutorial. (Also available from https://simplemaps.com/data/us-zips)
#
# Outline:
#   1. Create the CSV and write it out into Delta format
#   2. Create an unmanaged Delta table with the file output
#   3. Generate a manifest for this table
#

def main():
    
    # File location and type
    file_location = "./uszips.csv"
    file_type = "csv"

    # CSV options
    infer_schema = "true"
    first_row_is_header = "true"
    delimiter = ","

    # The applied options are for CSV files. For other file types, these will be ignored.
    df = spark.read.format(file_type) \
      .option("inferSchema", infer_schema) \
      .option("header", first_row_is_header) \
      .option("sep", delimiter) \
      .option("escape", "\"") \
      .load(file_location)


    delta_file_name = "uszips_delta_unmanaged"

    # write data out in Delta format
    df.write.format("delta").mode("overwrite").save("./delta/%s" % delta_file_name)


    # now create the Delta table (inside the metastore?)
    # NB: the location must be absolute!
    spark.sql('''
        CREATE TABLE default.uszips 
        USING DELTA 
        LOCATION '/home/ec2-user/dev/overcoil/prestoX-cluster/manifest/delta/uszips_delta_unmanaged';
    ''')

    # generate the manifest; 
    # NB: if you try to use a path after "FOR TABLE", the path must be delimited for the back-tick, not the single-quote!
    #     it's rather subtle in the docs too: https://docs.databricks.com/delta/presto-integration.html
    spark.sql('''
        GENERATE symlink_format_manifest 
        FOR TABLE default.uszips
    ''')


if __name__ == '__main__':
#    inputs = sys.argv[1]
#    output = sys.argv[2]
    main()
