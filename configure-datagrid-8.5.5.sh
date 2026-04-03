# Configure datagrid (no TLS)

export EAP_ZIP=$HOME/Downloads/redhat-datagrid-8.5.5-server.zip
export EAP_ZIP_ROOT="redhat-datagrid-8.5.5-server"

rm -rdf redhat-datagrid-8.5.5-server-1
unzip -q $EAP_ZIP
mv $EAP_ZIP_ROOT redhat-datagrid-8.5.5-server-1

rm -rdf redhat-datagrid-8.5.5-server-2
unzip -q $EAP_ZIP
mv $EAP_ZIP_ROOT redhat-datagrid-8.5.5-server-2

$PWD/redhat-datagrid-8.5.5-server-1/bin/cli.sh user create admin --password=pass.1234 --groups=admin
$PWD/redhat-datagrid-8.5.5-server-2/bin/cli.sh user create admin --password=pass.1234 --groups=admin

# Start datagrid

echo "$PWD/redhat-datagrid-8.5.5-server-1/bin/server.sh --bind-address=127.0.0.1 --cluster-address=127.0.0.1 --server-config=infinispan.xml --cluster-stack=tcp --cluster-name=cluster_234.99.54.24 --node-name=jdg1"

echo "$PWD/redhat-datagrid-8.5.5-server-2/bin/server.sh --port-offset=100 --bind-address=127.0.0.1 --cluster-address=127.0.0.1 --server-config=infinispan.xml --cluster-stack=tcp --cluster-name=cluster_234.99.54.24 --node-name=jdg2"
