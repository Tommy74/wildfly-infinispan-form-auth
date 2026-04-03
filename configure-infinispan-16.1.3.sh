# Configure datagrid (no TLS)

export EAP_ZIP=$HOME/Downloads/infinispan-server-16.1.3.zip
export EAP_ZIP_ROOT="infinispan-server-16.1.3"

rm -rdf infinispan-server-16.1.3-1
unzip -q $EAP_ZIP
mv $EAP_ZIP_ROOT infinispan-server-16.1.3-1

rm -rdf infinispan-server-16.1.3-2
unzip -q $EAP_ZIP
mv $EAP_ZIP_ROOT infinispan-server-16.1.3-2

$PWD/infinispan-server-16.1.3-1/bin/cli.sh user create admin --password=pass.1234 --groups=admin
$PWD/infinispan-server-16.1.3-2/bin/cli.sh user create admin --password=pass.1234 --groups=admin

# Start datagrid

echo "$PWD/infinispan-server-16.1.3-1/bin/server.sh --bind-address=127.0.0.1 --cluster-address=127.0.0.1 --server-config=infinispan.xml --cluster-stack=tcp --cluster-name=cluster_234.99.54.24 --node-name=jdg1"

echo "$PWD/infinispan-server-16.1.3-2/bin/server.sh --port-offset=100 --bind-address=127.0.0.1 --cluster-address=127.0.0.1 --server-config=infinispan.xml --cluster-stack=tcp --cluster-name=cluster_234.99.54.24 --node-name=jdg2"
