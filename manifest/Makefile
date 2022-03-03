
PY=spark-submit

USZIPSRC=https://cdn5.dcbstatic.com/files/d/a/databricks_docebosaas_com/1646362800/ZNFOsyW3iYCAwC5oI1Yx4Q/scorm/b99e0d0e31c5e56f6150d4ca9dfed7f98f4b267c/scormcontent/assets/JxKYmsK66N5yDrVw_6NWrBSOIRM-n7uQv-uszips.csv
USZIPS=uszips.csv

.phone=clean uszips

run: CreateUnmanagedTable.py
	$(PY) --packages io.delta:delta-core_2.12:1.1.0 \
		--conf "spark.sql.extensions=io.delta.sql.DeltaSparkSessionExtension" \
		--conf "spark.sql.catalog.spark_catalog=org.apache.spark.sql.delta.catalog.DeltaCatalog" \
		CreateUnmanagedTable.py

clean:
	# Nothing needed for cleaning at present

uszips: 
	curl -o $(USZIPS) $(USZIPSRC)

ls:
	hdfs dfs -ls /user/kaiyeec

cp:
	hdfs dfs -copyFromLocal $(USZIPS) /user/kaiyeec/$(USZIPS)

