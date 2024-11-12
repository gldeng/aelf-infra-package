zookeeper_module = import_module("/zookeeper.star")
kafka_module = import_module("/kafka.star")
elasticsearch_module = import_module("/elasticsearch.star")
kibana_module = import_module("/kibana.star")
redis_module = import_module("github.com/kurtosis-tech/redis-package/main.star")
mongodb_module = import_module("/mongodb.star")
rabbitmq_module = import_module("github.com/kurtosis-tech/rabbitmq-package/main.star")

def run(
    plan,
    need_redis=False,
    need_mongodb=False,
    need_rabbitmq=False,
    need_kafka=False,
    need_elasticsearch=False,
    need_kibana=False,
):
    if need_kibana and not need_elasticsearch:
        fail("Kibana requires Elasticsearch. Set need_elasticsearch=True when need_kibana=True.")
    
    output = {
        "kafka_host_port": None,
        "elasticsearch_url": None,
        "redis_url": None,
        "mongodb_url": None,
        "rabbitmq_node_hostname": None,
        "rabbitmq_node_port": None,
        "rabbitmq_node_names": None,
    }

    if need_redis:
        redis_info = redis_module.run(plan)
        redis_url = redis_info.url
        output["redis_url"] = redis_url
    if need_kafka:
        zookeeper_service = zookeeper_module.run(plan)
        kafka_host_port = kafka_module.run(plan)
        output["kafka_host_port"] = kafka_host_port
    if need_elasticsearch:
        elasticsearch_url = elasticsearch_module.run(plan)
        output["elasticsearch_url"] = elasticsearch_url
    if need_kibana:
        kibana_module.run(plan, elasticsearch_url)
    if need_mongodb:
        mongodb_info = mongodb_module.run(plan, {})
        mongodb_url = mongodb_info.url
        output["mongodb_url"] = mongodb_url
    if need_rabbitmq:
        rabbitmq_node_names = rabbitmq_module.run(plan,
            {
                "rabbitmq_num_nodes": 1,
                "rabbitmq_image": "rabbitmq:3.13-management",
                "rabbitmq_vhost": "/",
            })["node_names"]
        rabbitmq_service = plan.get_service(rabbitmq_node_names[0])
        output["rabbitmq_node_hostname"] = rabbitmq_service.hostname
        output["rabbitmq_node_port"] = rabbitmq_service.ports["amqp"].number
        output["rabbitmq_node_names"] = rabbitmq_node_names
    return output
