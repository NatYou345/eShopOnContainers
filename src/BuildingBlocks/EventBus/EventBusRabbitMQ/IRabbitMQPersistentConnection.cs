namespace Microsoft.eShopOnContainers.BuildingBlocks.EventBusRabbitMQ;

public interface IRabbitMQPersistentConnection
    : IDisposable
{
    bool IsConnected { get; }

    bool TryConnect();

    Task<IChannel> CreateModelAsync();
}
