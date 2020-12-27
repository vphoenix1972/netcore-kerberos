using Microsoft.AspNetCore.Authentication.Negotiate;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace NetCoreKerberos.Controllers
{
    public class HomeController : Controller
    {
        [Authorize(AuthenticationSchemes = NegotiateDefaults.AuthenticationScheme)]
        public IActionResult Index()
        {
            return Ok($"Success! User: {User.Identity.Name}");
        }
    }
}