using Azure.Messaging.ServiceBus;
using Microsoft.Azure.Cosmos;
using Microsoft.Azure.Functions.Extensions.DependencyInjection;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using TransactionGenerator;

[assembly: FunctionsStartup(typeof(Startup))]
namespace TransactionGenerator
{
    public class Startup : FunctionsStartup
    {
        public override void Configure(IFunctionsHostBuilder builder)
        {
            var config = new ConfigurationBuilder()
                .SetBasePath(Directory.GetCurrentDirectory())
                .AddJsonFile("local.settings.json", optional: true, reloadOnChange: true)
                .AddEnvironmentVariables()
                .Build();

            builder.Services.AddLogging();
            builder.Services.AddSingleton<IConfiguration>(config);
            builder.Services.AddSingleton(sp =>
            {
                IConfiguration configuration = sp.GetRequiredService<IConfiguration>();
                CosmosClientOptions cosmosClientOptions = new CosmosClientOptions
                {
                    MaxRetryAttemptsOnRateLimitedRequests = 3,
                    MaxRetryWaitTimeOnRateLimitedRequests = TimeSpan.FromSeconds(10)
                };
                return new CosmosClient(configuration["COSMOS_CONNECTION_STRING"], cosmosClientOptions);
            });
            builder.Services.AddSingleton(sp =>
            {
                IConfiguration configuration = sp.GetRequiredService<IConfiguration>();
                return new ServiceBusClient(configuration["SERVICE_BUS_CONNECTION_STRING"]);
            });
        }
    }
}
