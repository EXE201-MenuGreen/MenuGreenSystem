using System.Threading.Tasks;
using MenuGreen.BusinessLogicLayer.DTOs.Requests;
using MenuGreen.BusinessLogicLayer.DTOs.Responses;

namespace MenuGreen.BusinessLogicLayer.Interfaces
{
    public interface INutritionAssistantService
    {
        Task<NutritionAssistantChatResponse> SendMessageAsync(string userId, NutritionAssistantChatRequest request);
    }
}
