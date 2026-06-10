using System;
using System.IO;
using System.Threading.Tasks;
using MenuGreen.BusinessLogicLayer.DTOs.Responses;

namespace MenuGreen.BusinessLogicLayer.Interfaces
{
    public interface ICvService
    {
        /// <summary>
        /// Analyzes a food image stream by forwarding it to the FastAPI microservice,
        /// polling for completion, verifying allergy risks, logging the action,
        /// and returning the result.
        /// </summary>
        Task<CvInferenceResponse> AnalyzeImageAsync(Guid userId, Stream imageStream, string fileName, string contentType);
    }
}
