# Sandbox to test Camunda without Keycloak
## Steps to reproduce
- Set CAMUNDA_PLATFORM_VERSION in .env file to **8.4.5**
- Start docker compose with

    `docker compose -d up`
- Attach shell to the nicolaka/netshoot container
- Execute the follwoing command

    `/tmp/netshoot/topology.sh`
- **Success**
- What it does
    - Creates access token by the idp with client credentials flow
    - Calls method Topology of the zeebe gRPC interface without authentication header
    - Calls method Topology of the zeebe gRPC interface with authentication header
- Set CAMUNDA_PLATFORM_VERSION in .env file to **8.5.0**
- Restart with

    `docker compose -d up`
- Execute the follwoing command

    `/tmp/netshoot/topology.sh`
- **FAIL**
    - Check zeebe log to see the exception
- Shutdown with

    `docker compose down`
