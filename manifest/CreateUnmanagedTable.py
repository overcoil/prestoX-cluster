# import sys
# assert sys.version_info >= (3, 5) # make sure we have Python 3.5+

# from pyspark.sql import SparkSession, functions, types
# spark = SparkSession.builder.appName('CreateUnmanagedTable').getOrCreate()
# assert spark.version >= '2.3' # make sure we have Spark 2.3+

# from delta import *


# header as described from: https://docs.delta.io/latest/quick-start.html
import pyspark
from delta import *

builder = pyspark.sql.SparkSession.builder.appName("MyApp") \
    .config("spark.sql.extensions", "io.delta.sql.DeltaSparkSessionExtension") \
    .config("spark.sql.catalog.spark_catalog", "org.apache.spark.sql.delta.catalog.DeltaCatalog")

spark = configure_spark_with_delta_pip(builder).getOrCreate()

# 
# Translation of the Employee Academy tutorial's CreateUnmanagedTable.dbc
#
# This is a standalone program suitable for Pyspark (as opposed to the .dbc) which
#   runs on a cluster (either Databricks Cloud or local/standalone)
#

def main():
    
    # CMD 2:

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

    print(df)

    # CMD 3:

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
