db.getSiblingDB("unifi").createUser({
    user: "unifi",
    pwd: "z53S1J45b0eucTk1",
    roles: [{role: "dbOwner", db: "unifi"}]
});
db.getSiblingDB("unifi_stat").createUser({
    user: "unifi",
    pwd: "z53S1J45b0eucTk1",
    roles: [{role: "dbOwner", db: "unifi_stat"}]
});
