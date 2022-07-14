using Azure.Messaging.ServiceBus;
using Bogus;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Azure.WebJobs;
using Microsoft.Azure.WebJobs.Extensions.Http;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;
using Newtonsoft.Json;
using System;
using System.Threading.Tasks;
using TransactionGenerator.Models;

namespace TransactionGenerator.Functions
{
    public class GenerateTransactions
    {
        private readonly ILogger<GenerateTransactions> _logger;
        private readonly ServiceBusClient _serviceBusClient;
        private readonly ServiceBusSender _serviceBusSender;
        private readonly IConfiguration _configuration;

        public GenerateTransactions(ILogger<GenerateTransactions> logger,
            ServiceBusClient serviceBusClient,
            IConfiguration configuration)
        {
            _logger = logger;
            _serviceBusClient = serviceBusClient;
            _configuration = configuration;
            _serviceBusSender = _serviceBusClient.CreateSender(_configuration["QUEUE_NAME"]);
        }

        [FunctionName(nameof(GenerateTransactions))]
        public async Task<IActionResult> Run(
            [HttpTrigger(AuthorizationLevel.Anonymous, "get", Route = "transactions/{numberOfTransactions}")] HttpRequest req,
            int numberOfTransactions)
        {
            try
            {
                var transactions = new Faker<Transaction>()
                    .RuleFor(i => i.Id, (fake) => Guid.NewGuid().ToString())
                    .RuleFor(i => i.TransactionId, (fake) => Guid.NewGuid().ToString())
                    .RuleFor(i => i.ProductName, (fake) => fake.Commerce.Product())
                    .RuleFor(i => i.PurchaseAmount, (fake) => Math.Round(fake.Random.Decimal(1.99m, 199.99m), 2))
                    .RuleFor(i => i.PurchaseDate, (fake) => DateTime.UtcNow)
                    .Generate(numberOfTransactions);

                using ServiceBusMessageBatch messageBatch = await _serviceBusSender.CreateMessageBatchAsync();
                foreach (var transaction in transactions)
                {
                    _logger.LogInformation($"Sending Transaction Id: {transaction.TransactionId} to service bus queue: {_configuration["QUEUE_NAME"]}");
                    messageBatch.TryAddMessage(new ServiceBusMessage(JsonConvert.SerializeObject(transaction)));
                }

                await _serviceBusSender.SendMessagesAsync(messageBatch);

                return new OkResult();
            }
            catch (Exception ex)
            {
                _logger.LogError($"Exception thrown in {nameof(GenerateTransactions)}: {ex.Message}");
                throw;
            }
        }
    }
}
