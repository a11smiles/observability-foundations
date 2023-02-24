namespace todo.Controllers
{
    using System;
    using System.Collections.Generic;
    using System.Threading.Tasks;
    using Microsoft.AspNetCore.Mvc;
    using Microsoft.Extensions.Logging;
    using Newtonsoft.Json;
    using todo.Models;

    public class ItemController : Controller
    {
        private readonly ILogger _logger;
        private readonly ICosmosDbService _cosmosDbService;
        public ItemController(ILogger<ItemController> logger, ICosmosDbService cosmosDbService)
        {
            _logger = logger;
            _cosmosDbService = cosmosDbService;
        }

        [ActionName("Index")]
        public async Task<IActionResult> Index()
        {
            using (_logger.BeginScope(new Dictionary<string, object>{
                ["HttpVerb"] = "Get",
                ["Action"] = "Index",
                ["TransactionId"] = Guid.NewGuid()
            })) {
                _logger.LogInformation("Loading index.");
            
                return View(await _cosmosDbService.GetItemsAsync("SELECT * FROM c"));
            }
        }

        [ActionName("Create")]
        public IActionResult Create()
        {
            using (_logger.BeginScope(new Dictionary<string, object>{
                ["HttpVerb"] = "Get",
                ["Action"] = "Create",
                ["TransactionId"] = Guid.NewGuid()
            })) {
                _logger.LogInformation("Loading create.");
                
                return View();
            }
        }

        [HttpPost]
        [ActionName("Create")]
        [ValidateAntiForgeryToken]
        public async Task<ActionResult> CreateAsync([Bind("Id,Name,Description,Category,Completed")] Item item)
        {
            using (_logger.BeginScope(new Dictionary<string, object>{
                ["HttpVerb"] = "Post",
                ["Action"] = "Create",
                ["TransactionId"] = Guid.NewGuid()
            })) {
                _logger.LogDebug("Attempting to create todo {item}", JsonConvert.SerializeObject(item));
                
                if (ModelState.IsValid)
                {
                    item.Id = Guid.NewGuid().ToString();

                    _logger.LogDebug("Todo Data {item}", JsonConvert.SerializeObject(item));
                    await _cosmosDbService.AddItemAsync(item);
                    _logger.LogDebug("Todo ({id}) created.", item.Id);
                    return RedirectToAction("Index");
                }

                _logger.LogWarning("Creating todo failed: invalid model {item}", JsonConvert.SerializeObject(item));
                return View(item);
            }
        }

        [HttpPost]
        [ActionName("Edit")]
        [ValidateAntiForgeryToken]
        public async Task<ActionResult> EditAsync([Bind("Id,Name,Description,Category,Completed")] Item item)
        {
            using (_logger.BeginScope(new Dictionary<string, object>{
                ["HttpVerb"] = "Post",
                ["Action"] = "Edit",
                ["TransactionId"] = Guid.NewGuid()
            })) {
                _logger.LogDebug("Attempting to modify todo ({id}).", item.Id);

                if (ModelState.IsValid)
                {
                    _logger.LogDebug("Todo Data {item}", JsonConvert.SerializeObject(item));
                    await _cosmosDbService.UpdateItemAsync(item);
                    _logger.LogDebug("Todo ({id}) modified.", item.Id);
                    return RedirectToAction("Index");
                }

                _logger.LogWarning("Modifying todo failed: invalid model {item}", JsonConvert.SerializeObject(item));
                return View(item);
            }
        }

        [ActionName("Edit")]
        public async Task<ActionResult> EditAsync(string id, string category)
        {
            using (_logger.BeginScope(new Dictionary<string, object>{
                ["HttpVerb"] = "Get",
                ["Action"] = "Edit",
                ["TransactionId"] = Guid.NewGuid()
            })) {
                _logger.LogInformation("Attempting to modify todo ({id}, {category}).", id, category);

                if (id == null)
                {
                    _logger.LogError("When attempting to modify todo, id is null.");
                    return BadRequest();
                }

                Item item = await _cosmosDbService.GetItemAsync(id, category);
                if (item == null)
                {
                    _logger.LogError("When attempting to modify todo, id is not found ({id}, {category}).", id, category);
                    return NotFound();
                }

                _logger.LogDebug("Attempting to modify todo {item}", JsonConvert.SerializeObject(item));
                return View(item);
            }
        }

        [ActionName("Delete")]
        public async Task<ActionResult> DeleteAsync(string id, string category)
        {
            using (_logger.BeginScope(new Dictionary<string, object>{
                ["HttpVerb"] = "Get",
                ["Action"] = "Delete",
                ["TransactionId"] = Guid.NewGuid()
            })) {
                _logger.LogInformation("Attempting to delete todo ({id}, {category}).", id, category);

                if (id == null)
                {
                    _logger.LogError("When attempting to delete todo, id is null.");
                    return BadRequest();
                }

                Item item = await _cosmosDbService.GetItemAsync(id, category);
                if (item == null)
                {
                    _logger.LogError("When attempting to delete todo, id is not found ({id}, {category}).", id, category);
                    return NotFound();
                }

                _logger.LogDebug("Attempting to delete todo {item}", JsonConvert.SerializeObject(item));
                return View(item);
            }
        }

        [HttpPost]
        [ActionName("Delete")]
        [ValidateAntiForgeryToken]
        public async Task<ActionResult> DeleteConfirmedAsync([Bind("Id")] string id, [Bind("Category")] string category)
        {
            using (_logger.BeginScope(new Dictionary<string, object>{
                ["HttpVerb"] = "Post",
                ["Action"] = "Delete",
                ["TransactionId"] = Guid.NewGuid()
            })) {
                _logger.LogDebug("Attempting to delete todo ({id}, {category}).", id, category);
            
                await _cosmosDbService.DeleteItemAsync(id, category);
                _logger.LogDebug("Todo ({id}, {category}) deleted.", id, category);
            
                return RedirectToAction("Index");
            }
        }

        [ActionName("Details")]
        public async Task<ActionResult> DetailsAsync(string id, string category)
        {
            using (_logger.BeginScope(new Dictionary<string, object>{
                ["HttpVerb"] = "Get",
                ["Action"] = "Details",
                ["TransactionId"] = Guid.NewGuid()
            })) {
                _logger.LogDebug("Viewing item ({id}, {category}).", id, category);

                return View(await _cosmosDbService.GetItemAsync(id, category));
            }
        }
    }
}
