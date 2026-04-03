# Configure wildfly (SSO without TLS)

export EAP_ZIP=$HOME/Downloads/jboss-eap-8.1.6.GA-CR2.zip
export EAP_ZIP_ROOT="jboss-eap-8.1"

rm -rdf jboss-eap-8.1-1
unzip -q $EAP_ZIP
mv $EAP_ZIP_ROOT jboss-eap-8.1-1

rm -rdf jboss-eap-8.1-2
unzip -q $EAP_ZIP
mv $EAP_ZIP_ROOT jboss-eap-8.1-2

cat <<EOF > $PWD/wildfly1.cli
embed-server --server-config=standalone-ha.xml

if (outcome != success) of /subsystem=jgroups:read-attribute(name=default-stack)
  /subsystem=jgroups/channel=ee:write-attribute(name=stack,value=tcp)
else
  /subsystem=jgroups:write-attribute(name=default-stack,value=tcp)
  /subsystem=jgroups/channel=ee:write-attribute(name=stack,value=tcp)
end-if
/subsystem=transactions:write-attribute(name=node-identifier,value=wildfly1)
/socket-binding-group=standard-sockets/remote-destination-outbound-socket-binding=remote-jdg-server1:add(host=127.0.0.1, port=11222)
/socket-binding-group=standard-sockets/remote-destination-outbound-socket-binding=remote-jdg-server2:add(host=127.0.0.1, port=11322)
batch
/subsystem=infinispan/remote-cache-container=web-sessions:add(default-remote-cluster=jdg-server-cluster, statistics-enabled=true, properties={infinispan.client.hotrod.auth_username=admin, infinispan.client.hotrod.auth_password=pass.1234})
/subsystem=infinispan/remote-cache-container=web-sessions/remote-cluster=jdg-server-cluster:add(socket-bindings=[remote-jdg-server1,remote-jdg-server2])
run-batch
if (outcome == success) of /subsystem=infinispan/remote-cache-container=web-sessions:read-attribute(name=marshaller)
/subsystem=infinispan/remote-cache-container=web-sessions:write-attribute(name=marshaller,value=PROTOSTREAM)
end-if
/subsystem=infinispan/cache-container=web/invalidation-cache=offload:add()
/subsystem=infinispan/cache-container=web/invalidation-cache=offload/store=hotrod:add(remote-cache-container=web-sessions, fetch-state=false, preload=false, passivation=false, purge=false, shared=true)
/subsystem=infinispan/cache-container=web/invalidation-cache=offload/component=transaction:add(mode=BATCH)
/subsystem=infinispan/cache-container=web:write-attribute(name=default-cache, value=offload)
/subsystem=infinispan/cache-container=ejb/invalidation-cache=offload:add()
/subsystem=infinispan/cache-container=ejb/invalidation-cache=offload/store=hotrod:add(remote-cache-container=web-sessions, fetch-state=false, preload=false, passivation=false, purge=false, shared=true)
/subsystem=infinispan/cache-container=ejb/invalidation-cache=offload/component=transaction:add(mode=BATCH)
/subsystem=infinispan/cache-container=ejb:write-attribute(name=default-cache, value=offload)
/subsystem=elytron/filesystem-realm=clustering-realm:add(path=clustering-realm, relative-to=jboss.server.config.dir)
/subsystem=elytron/security-domain=clustering-domain:add(default-realm=clustering-realm, permission-mapper=default-permission-mapper,realms=[{realm=clustering-realm, role-decoder=groups-to-roles}])
/subsystem=elytron/filesystem-realm=clustering-realm:add-identity(identity=ssoUser)
/subsystem=elytron/filesystem-realm=clustering-realm:set-password(identity=ssoUser, clear={password=ssoPassw})
/subsystem=elytron/filesystem-realm=clustering-realm:add-identity-attribute(identity=ssoUser, name=groups, value=["User"])
/subsystem=elytron/http-authentication-factory=clustering-http-authentication:add(security-domain=clustering-domain, http-server-mechanism-factory=global, mechanism-configurations=[{mechanism-name=FORM}])
if (outcome == success) of /subsystem=undertow/application-security-domain=other:read-resource
/subsystem=undertow/application-security-domain=other:remove
end-if
/subsystem=undertow/application-security-domain=other:add(http-authentication-factory=clustering-http-authentication)
batch
/subsystem=infinispan/remote-cache-container=sso_data_cc:add(default-remote-cluster=jdg-server-cluster, statistics-enabled=true, properties={infinispan.client.hotrod.auth_username=admin, infinispan.client.hotrod.auth_password=pass.1234})
/subsystem=infinispan/remote-cache-container=sso_data_cc/remote-cluster=jdg-server-cluster:add(socket-bindings=[remote-jdg-server1,remote-jdg-server2])
run-batch
if (outcome == success) of /subsystem=infinispan/remote-cache-container=sso_data_cc:read-attribute(name=modules)
    /subsystem=infinispan/remote-cache-container=sso_data_cc:write-attribute(name=modules,value=[org.wildfly.clustering.web.hotrod])
else
    /subsystem=infinispan/remote-cache-container=sso_data_cc:write-attribute(name=module,value=org.wildfly.clustering.web.hotrod)
end-if
/subsystem=distributable-web/hotrod-single-sign-on-management=other:add(remote-cache-container=sso_data_cc)
/subsystem=distributable-web:write-attribute(name=default-single-sign-on-management, value=other)
if (outcome == success) of /subsystem=infinispan/remote-cache-container=sso_data_cc:read-children-resources(child-type=near-cache)
/subsystem=infinispan/remote-cache-container=sso_data_cc/near-cache=invalidation:add(max-entries=1000)
end-if
if (outcome == success) of /subsystem=infinispan/remote-cache-container=sso_data_cc:read-attribute(name=marshaller)
/subsystem=infinispan/remote-cache-container=sso_data_cc:write-attribute(name=marshaller,value=PROTOSTREAM)
end-if
EOF

cat <<EOF > $PWD/wildfly2.cli
embed-server --server-config=standalone-ha.xml

if (outcome != success) of /subsystem=jgroups:read-attribute(name=default-stack)
  /subsystem=jgroups/channel=ee:write-attribute(name=stack,value=tcp)
else
  /subsystem=jgroups:write-attribute(name=default-stack,value=tcp)
  /subsystem=jgroups/channel=ee:write-attribute(name=stack,value=tcp)
end-if
/subsystem=transactions:write-attribute(name=node-identifier,value=wildfly2)
/socket-binding-group=standard-sockets/remote-destination-outbound-socket-binding=remote-jdg-server1:add(host=127.0.0.1, port=11222)
/socket-binding-group=standard-sockets/remote-destination-outbound-socket-binding=remote-jdg-server2:add(host=127.0.0.1, port=11322)
batch
/subsystem=infinispan/remote-cache-container=web-sessions:add(default-remote-cluster=jdg-server-cluster, statistics-enabled=true, properties={infinispan.client.hotrod.auth_username=admin, infinispan.client.hotrod.auth_password=pass.1234})
/subsystem=infinispan/remote-cache-container=web-sessions/remote-cluster=jdg-server-cluster:add(socket-bindings=[remote-jdg-server1,remote-jdg-server2])
run-batch
if (outcome == success) of /subsystem=infinispan/remote-cache-container=web-sessions:read-attribute(name=marshaller)
/subsystem=infinispan/remote-cache-container=web-sessions:write-attribute(name=marshaller,value=PROTOSTREAM)
end-if
/subsystem=infinispan/cache-container=web/invalidation-cache=offload:add()
/subsystem=infinispan/cache-container=web/invalidation-cache=offload/store=hotrod:add(remote-cache-container=web-sessions, fetch-state=false, preload=false, passivation=false, purge=false, shared=true)
/subsystem=infinispan/cache-container=web/invalidation-cache=offload/component=transaction:add(mode=BATCH)
/subsystem=infinispan/cache-container=web:write-attribute(name=default-cache, value=offload)
/subsystem=infinispan/cache-container=ejb/invalidation-cache=offload:add()
/subsystem=infinispan/cache-container=ejb/invalidation-cache=offload/store=hotrod:add(remote-cache-container=web-sessions, fetch-state=false, preload=false, passivation=false, purge=false, shared=true)
/subsystem=infinispan/cache-container=ejb/invalidation-cache=offload/component=transaction:add(mode=BATCH)
/subsystem=infinispan/cache-container=ejb:write-attribute(name=default-cache, value=offload)
/subsystem=elytron/filesystem-realm=clustering-realm:add(path=clustering-realm, relative-to=jboss.server.config.dir)
/subsystem=elytron/security-domain=clustering-domain:add(default-realm=clustering-realm, permission-mapper=default-permission-mapper,realms=[{realm=clustering-realm, role-decoder=groups-to-roles}]
/subsystem=elytron/filesystem-realm=clustering-realm:add-identity(identity=ssoUser)
/subsystem=elytron/filesystem-realm=clustering-realm:set-password(identity=ssoUser, clear={password=ssoPassw})
/subsystem=elytron/filesystem-realm=clustering-realm:add-identity-attribute(identity=ssoUser, name=groups, value=["User"])
/subsystem=elytron/http-authentication-factory=clustering-http-authentication:add(security-domain=clustering-domain, http-server-mechanism-factory=global, mechanism-configurations=[{mechanism-name=FORM}])
if (outcome == success) of /subsystem=undertow/application-security-domain=other:read-resource
/subsystem=undertow/application-security-domain=other:remove
end-if
/subsystem=undertow/application-security-domain=other:add(http-authentication-factory=clustering-http-authentication)
batch
/subsystem=infinispan/remote-cache-container=sso_data_cc:add(default-remote-cluster=jdg-server-cluster, statistics-enabled=true, properties={infinispan.client.hotrod.auth_username=admin, infinispan.client.hotrod.auth_password=pass.1234})
/subsystem=infinispan/remote-cache-container=sso_data_cc/remote-cluster=jdg-server-cluster:add(socket-bindings=[remote-jdg-server1,remote-jdg-server2])
run-batch
if (outcome == success) of /subsystem=infinispan/remote-cache-container=sso_data_cc:read-attribute(name=modules)
    /subsystem=infinispan/remote-cache-container=sso_data_cc:write-attribute(name=modules,value=[org.wildfly.clustering.web.hotrod])
else
    /subsystem=infinispan/remote-cache-container=sso_data_cc:write-attribute(name=module,value=org.wildfly.clustering.web.hotrod)
end-if
/subsystem=distributable-web/hotrod-single-sign-on-management=other:add(remote-cache-container=sso_data_cc)
/subsystem=distributable-web:write-attribute(name=default-single-sign-on-management, value=other)
if (outcome == success) of /subsystem=infinispan/remote-cache-container=sso_data_cc:read-children-resources(child-type=near-cache)
/subsystem=infinispan/remote-cache-container=sso_data_cc/near-cache=invalidation:add(max-entries=1000)
end-if
if (outcome == success) of /subsystem=infinispan/remote-cache-container=sso_data_cc:read-attribute(name=marshaller)
/subsystem=infinispan/remote-cache-container=sso_data_cc:write-attribute(name=marshaller,value=PROTOSTREAM)
end-if
EOF

echo -e "\n=============================\nConfigure WF 1\n=============================\n\n"
$PWD/jboss-eap-8.1-1/bin/jboss-cli.sh --file=$PWD/wildfly1.cli --echo-command

echo -e "\n=============================\nConfigure WF 2\n=============================\n\n"
$PWD/jboss-eap-8.1-2/bin/jboss-cli.sh --file=$PWD/wildfly2.cli --echo-command

$PWD/jboss-eap-8.1-1/bin/add-user.sh -u admin -p pass.1234
$PWD/jboss-eap-8.1-2/bin/add-user.sh -u admin -p pass.1234

# Build and deploy form-auth-webapp
cd $PWD/form-auth-webapp && mvn -q clean package && cd ..
cp $PWD/form-auth-webapp/target/form-auth-webapp.war $PWD/jboss-eap-8.1-1/standalone/deployments/
cp $PWD/form-auth-webapp/target/form-auth-webapp.war $PWD/jboss-eap-8.1-2/standalone/deployments/

# Start wildfly

echo "$PWD/jboss-eap-8.1-1/bin/standalone.sh --server-config=standalone-ha.xml -Djboss.default.multicast.address=230.0.0.190 -Djboss.node.name=wildfly1 -Djboss.socket.binding.port-offset=100"

echo "$PWD/jboss-eap-8.1-2/bin/standalone.sh --server-config=standalone-ha.xml -Djboss.default.multicast.address=230.0.0.190 -Djboss.node.name=wildfly2 -Djboss.socket.binding.port-offset=400"

echo "http://localhost:8180/form-auth-webapp/session"
