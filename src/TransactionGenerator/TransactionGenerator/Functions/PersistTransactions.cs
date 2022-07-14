using Microsoft.Azure.Cosmos;
using Microsoft.Azure.WebJobs;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;
using Newtonsoft.Json;
using System;
using System.Threading.Tasks;
using TransactionGenerator.Models;

namespace TransactionGenerator.Functions
{
    public class PersistTransactions
    {
        private readonly ILogger<PersistTransactions> _logger;
        private readonly IConfiguration _configuration;
        private readonly CosmosClient _client;
        private readonly Container _container;

        public PersistTransactions(ILogger<PersistTransactions> logger, IConfiguration configuration, CosmosClient client)
        {
            _logger=logger;
            _configuration=configuration;
            _client=client;
            _container = _client.GetContainer(_configuration["DATABASE_NAME"], _configuration["CONTAINER_NAME"]);
        }

        [FunctionName(nameof(PersistTransactions))]
        public async Task Run([ServiceBusTrigger("transactions", Connection = "SERVICE_BUS_CONNECTION_STRING")] string myQueueItem)
        {
            try
            {
                var transaction = JsonConvert.DeserializeObject<Transaction>(myQueueItem);

                _logger.LogInformation($"Persisting Transaction Id: {transaction.TransactionId} to the database");
                await _container.CreateItemAsync(transaction, new PartitionKey(transaction.TransactionId));
                _logger.LogInformation($"Transaction Id: {transaction.TransactionId} saved to the database");
            }
            catch (Exception ex)
            {
                _logger.LogError($"Exception thrown in {nameof(PersistTransactions)}: {ex.Message}");
                throw;
            }
        }
    }
}
