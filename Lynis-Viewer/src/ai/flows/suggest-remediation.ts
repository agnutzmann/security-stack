// src/ai/flows/suggest-remediation.ts
'use server';
/**
 * @fileOverview An AI agent for suggesting remediation steps based on Lynis scan results.
 *
 * - suggestRemediation - A function that handles the remediation suggestion process.
 * - SuggestRemediationInput - The input type for the suggestRemediation function.
 * - SuggestRemediationOutput - The return type for the suggestRemediation function.
 */

import {ai} from '@/ai/ai-instance';
import {z} from 'genkit';

const SuggestRemediationInputSchema = z.object({
  finding: z.string().describe('A finding from a Lynis scan report.'),
  recommendation: z.string().describe('The recommendation from the Lynis scan report.'),
});

export type SuggestRemediationInput = z.infer<typeof SuggestRemediationInputSchema>;

const SuggestRemediationOutputSchema = z.object({
  riskAssessment: z
    .enum(['high', 'medium', 'low'])
    .describe('The risk assessment of the finding.'),
  summary: z.string().describe('A summary of the finding.'),
  remediationSteps: z.string().describe('Suggested remediation steps for the finding.'),
});

export type SuggestRemediationOutput = z.infer<typeof SuggestRemediationOutputSchema>;

export async function suggestRemediation(input: SuggestRemediationInput): Promise<SuggestRemediationOutput> {
  return suggestRemediationFlow(input);
}

const prompt = ai.definePrompt({
  name: 'suggestRemediationPrompt',
  input: {
    schema: z.object({
      finding: z.string().describe('A finding from a Lynis scan report.'),
      recommendation: z.string().describe('The recommendation from the Lynis scan report.'),
    }),
  },
  output: {
    schema: z.object({
      riskAssessment: z
        .enum(['high', 'medium', 'low'])
        .describe('The risk assessment of the finding.'),
      summary: z.string().describe('A summary of the finding.'),
      remediationSteps: z.string().describe('Suggested remediation steps for the finding.'),
    }),
  },
  prompt: `You are a security expert analyzing Lynis scan findings and providing remediation advice.

  Finding: {{{finding}}}
  Recommendation: {{{recommendation}}}

  Analyze the finding and recommendation. Provide a risk assessment (high, medium, or low), a summary of the finding, and detailed remediation steps to address the identified vulnerability. Focus on practical and effective solutions based on security best practices.
  Make sure the remediation steps are clear and actionable.
  `,
});

const suggestRemediationFlow = ai.defineFlow<
  typeof SuggestRemediationInputSchema,
  typeof SuggestRemediationOutputSchema
>({
  name: 'suggestRemediationFlow',
  inputSchema: SuggestRemediationInputSchema,
  outputSchema: SuggestRemediationOutputSchema,
}, async input => {
  const {output} = await prompt(input);
  return output!;
});
