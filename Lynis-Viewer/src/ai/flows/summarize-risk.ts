// SummarizeRisk story: As a user, I want the application to use AI to analyze Lynis scan results, categorize risks as high, medium, or low, and provide a concise summary of each finding to quickly understand potential security issues.

'use server';

/**
 * @fileOverview AI-powered risk analysis for Lynis scan results.
 *
 * - summarizeRisk - Analyzes Lynis scan results, categorizes risks, and provides a concise summary of each finding.
 * - SummarizeRiskInput - The input type for the summarizeRisk function.
 * - SummarizeRiskOutput - The return type for the summarizeRisk function (array of RiskAssessment).
 * - RiskAssessment - The type for a single risk assessment result.
 */

import {ai} from '@/ai/ai-instance';
import {z} from 'genkit';

const SummarizeRiskInputSchema = z.object({
  lynisReport: z
    .string()
    .describe('The Lynis report data, either in JSON or lynis-report.dat format.'),
});
export type SummarizeRiskInput = z.infer<typeof SummarizeRiskInputSchema>;

const RiskAssessmentSchema = z.object({
  riskLevel: z.enum(['high', 'medium', 'low']).describe('The risk level of the finding.'),
  summary: z.string().describe('A concise summary of the finding.'),
});
export type RiskAssessment = z.infer<typeof RiskAssessmentSchema>; // Export the element type

const SummarizeRiskOutputSchema = z.array(RiskAssessmentSchema);
export type SummarizeRiskOutput = RiskAssessment[]; // Use the defined type

export async function summarizeRisk(input: SummarizeRiskInput): Promise<SummarizeRiskOutput> {
  return summarizeRiskFlow(input);
}

const summarizeRiskPrompt = ai.definePrompt({
  name: 'summarizeRiskPrompt',
  input: {
    schema: z.object({
      lynisReport: z
        .string()
        .describe('The Lynis report data, either in JSON or lynis-report.dat format.'),
    }),
  },
  output: {
    schema: z.array(RiskAssessmentSchema), // Keep using the schema array for output definition
  },
  prompt: `You are a security expert analyzing Lynis scan reports. 

  Analyze the following Lynis report findings and categorize each finding as high, medium, or low risk. Provide a concise summary of each finding.

  Lynis Report:
  {{lynisReport}}

  For each finding, determine the risk level (high, medium, or low) and provide a short summary. Return a JSON array of risk assessments.
  `,
});

const summarizeRiskFlow = ai.defineFlow<
  typeof SummarizeRiskInputSchema,
  typeof SummarizeRiskOutputSchema
>({
  name: 'summarizeRiskFlow',
  inputSchema: SummarizeRiskInputSchema,
  outputSchema: SummarizeRiskOutputSchema,
},
async input => {
  const {output} = await summarizeRiskPrompt(input);
  // Ensure output is an array, return empty array if null/undefined
  return output ?? [];
});


