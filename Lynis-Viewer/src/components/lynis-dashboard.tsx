
'use client';

import React, { useState, useEffect, useCallback, useMemo } from 'react';
import type { ChangeEvent } from 'react';
import { FileUp, AlertTriangle, CheckCircle, ShieldAlert, ShieldCheck, ShieldQuestion, Loader2 } from 'lucide-react';
import { Button } from '@/components/ui/button';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Input } from '@/components/ui/input';
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs';
import { Accordion, AccordionContent, AccordionItem, AccordionTrigger } from '@/components/ui/accordion';
import { Badge } from '@/components/ui/badge';
import { useToast } from '@/hooks/use-toast';
import { summarizeRisk, type SummarizeRiskOutput, type RiskAssessment } from '@/ai/flows/summarize-risk'; // Import RiskAssessment
import { suggestRemediation, type SuggestRemediationOutput } from '@/ai/flows/suggest-remediation';
import { Alert, AlertDescription, AlertTitle } from '@/components/ui/alert';
import { Skeleton } from '@/components/ui/skeleton';
import { Progress } from '@/components/ui/progress';
import { Tooltip, TooltipContent, TooltipProvider, TooltipTrigger } from '@/components/ui/tooltip';

interface LynisFinding {
  id: string;
  finding: string;
  recommendation: string;
  details?: string;
}

interface ParsedReport {
  findings: LynisFinding[];
  warnings: LynisFinding[];
  suggestions: LynisFinding[];
  status: string; // Example: "Hardened", "Needs Improvement", etc.
}

// Corrected interface definition
interface RiskAnalysisResult extends RiskAssessment { // Extend the imported RiskAssessment type
  id: string; // Corresponds to LynisFinding id
  remediation?: SuggestRemediationOutput;
  isLoadingRemediation?: boolean;
}

// Simple parser for lynis-report.dat format (adapt as needed for actual structure)
const parseLynisDatReport = (content: string): ParsedReport => {
  const lines = content.split('\n');
  const findings: LynisFinding[] = [];
  const warnings: LynisFinding[] = [];
  const suggestions: LynisFinding[] = [];
  let status = 'Unknown';

  lines.forEach(line => {
    const parts = line.split('=');
    if (parts.length >= 2) {
      const key = parts[0];
      const value = parts.slice(1).join('=');

      if (key.startsWith('suggestion[]') || key.startsWith('warning[]')) {
        const findingType = key.startsWith('suggestion') ? 'suggestion' : 'warning';
        const parts = value.split('|');
        const id = parts[0];
        const findingText = parts[1] || 'No details provided';
        const recommendationText = parts[2] || 'No recommendation provided';

        const findingObj: LynisFinding = {
          id: id,
          finding: findingText.trim(),
          recommendation: recommendationText.trim(),
        };

        if (findingType === 'warning') {
          warnings.push(findingObj);
        } else {
          suggestions.push(findingObj);
        }
        // Add to overall findings as well if needed, or keep separate
         findings.push(findingObj);

      } else if (key === 'hardening_index') {
        const index = parseInt(value, 10);
        if (!isNaN(index)) {
          if (index >= 80) status = 'Hardened';
          else if (index >= 60) status = 'Needs Improvement';
          else status = 'Vulnerable';
        }
      }
      // Add more parsing logic for other sections as needed
    }
  });

  // Example: Placeholder for findings if not parsed above
    if (findings.length === 0) {
        findings.push({ id: 'Placeholder', finding: 'No specific findings parsed (DAT parser needs refinement)', recommendation: 'Review the raw report data.' });
    }


  return { findings, warnings, suggestions, status };
};


export function LynisDashboard() {
  const [reportContent, setReportContent] = useState<string | null>(null);
  const [parsedReport, setParsedReport] = useState<ParsedReport | null>(null);
  const [riskAnalysis, setRiskAnalysis] = useState<RiskAnalysisResult[] | null>(null);
  const [fileName, setFileName] = useState<string | null>(null);
  const [isLoading, setIsLoading] = useState(false);
  const [isParsing, setIsParsing] = useState(false);
  const [isAnalyzing, setIsAnalyzing] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const { toast } = useToast();

  const handleFileChange = (event: ChangeEvent<HTMLInputElement>) => {
    const file = event.target.files?.[0];
    if (file) {
      setIsLoading(true);
      setError(null);
      setFileName(file.name);
      const reader = new FileReader();
      reader.onload = (e) => {
        const content = e.target?.result as string;
        setReportContent(content);
        setIsLoading(false);
        toast({
          title: 'File Ready',
          description: `${file.name} loaded successfully. Click "Analyze Report" to proceed.`,
        });
      };
      reader.onerror = () => {
        setError('Failed to read the file.');
        toast({
          title: 'Error',
          description: 'Failed to read the file.',
          variant: 'destructive',
        });
        setIsLoading(false);
      };
      reader.readAsText(file);
    }
  };

  const parseReport = useCallback(() => {
    if (!reportContent) return;

    setIsParsing(true);
    setError(null);

    try {
      // Simple check for JSON format
      let parsed: ParsedReport;
      if (reportContent.trim().startsWith('{')) {
        // Basic JSON parsing - adapt to actual Lynis JSON structure
        const jsonData = JSON.parse(reportContent);
        // Example mapping (adjust based on actual Lynis JSON structure)
        parsed = {
            findings: jsonData.findings?.map((f: any, index: number) => ({
                id: f.id || `finding-${index}`,
                finding: f.description || 'N/A',
                recommendation: f.recommendation || 'N/A',
                details: f.details || '',
            })) || [],
            warnings: jsonData.warnings?.map((w: any, index: number) => ({
                id: w.id || `warning-${index}`,
                finding: w.description || 'N/A',
                recommendation: w.recommendation || 'N/A',
                details: w.details || '',
            })) || [],
            suggestions: jsonData.suggestions?.map((s: any, index: number) => ({
                 id: s.id || `suggestion-${index}`,
                finding: s.description || 'N/A',
                recommendation: s.recommendation || 'N/A',
                 details: s.details || '',
            })) || [],
             status: jsonData.status || 'Unknown'
        };
         // Fallback if primary fields aren't found
        if (parsed.findings.length === 0 && jsonData.tests) {
             parsed.findings = Object.values(jsonData.tests).map((test: any) => ({
                 id: test.test_id,
                 finding: test.description,
                 recommendation: test.suggestion || 'N/A',
                 details: test.output,
            }));
        }


      } else {
        // Assume .dat format
        parsed = parseLynisDatReport(reportContent);
      }

      if (!parsed || (!parsed.findings?.length && !parsed.warnings?.length && !parsed.suggestions?.length)) {
        throw new Error('Could not parse meaningful data from the report. Check format.');
      }

      setParsedReport(parsed);
      toast({
        title: 'Parsing Complete',
        description: 'Report parsed successfully.',
      });
    } catch (err) {
      console.error('Parsing error:', err);
      const message = err instanceof Error ? err.message : 'Failed to parse the report. Ensure it is valid Lynis JSON or .dat format.';
       setError(message);
      toast({
        title: 'Parsing Error',
        description: message,
        variant: 'destructive',
      });
      setParsedReport(null);
    } finally {
      setIsParsing(false);
    }
  }, [reportContent, toast]);


  const analyzeRisk = useCallback(async () => {
      if (!parsedReport || (!parsedReport.findings.length && !parsedReport.warnings.length && !parsedReport.suggestions.length)) {
        toast({ title: 'Analysis Skipped', description: 'No parsed data to analyze.', variant: 'destructive' });
        return;
      }

    setIsAnalyzing(true);
    setError(null);
    setRiskAnalysis(null); // Clear previous analysis

    // Combine all items for analysis, prioritizing warnings
    const itemsToAnalyze = [
        ...parsedReport.warnings.map(w => ({ ...w, type: 'Warning' })),
        ...parsedReport.suggestions.map(s => ({ ...s, type: 'Suggestion' })),
        // Include findings only if they are distinct from warnings/suggestions
        ...parsedReport.findings.filter(f =>
            !parsedReport.warnings.some(w => w.id === f.id) &&
            !parsedReport.suggestions.some(s => s.id === f.id)
        ).map(f => ({ ...f, type: 'Finding' }))
    ];

     // Limit the number of findings sent to the AI to avoid overwhelming it or hitting limits
     const ANALYSIS_LIMIT = 50;
     const limitedItems = itemsToAnalyze.slice(0, ANALYSIS_LIMIT);

     if (itemsToAnalyze.length > ANALYSIS_LIMIT) {
         toast({
             title: 'Analysis Limited',
             description: `Analyzing the first ${ANALYSIS_LIMIT} findings out of ${itemsToAnalyze.length}.`,
             variant: 'default'
         });
     }


    const reportSummaryForAI = limitedItems
      .map(item => `ID: ${item.id}\nType: ${item.type}\nFinding: ${item.finding}\nRecommendation: ${item.recommendation}\n---`)
      .join('\n');

    try {
      const analysisResult = await summarizeRisk({ lynisReport: reportSummaryForAI });

      if (!analysisResult || analysisResult.length === 0) {
          throw new Error('AI analysis returned no results. The report might be empty or the AI could not process it.');
      }


        // Map AI results back to original finding IDs
        const mappedAnalysis: RiskAnalysisResult[] = limitedItems.map((item, index) => {
            // Find the corresponding AI result. This assumes the AI returns results in the same order.
            // If the AI doesn't guarantee order, a more robust matching based on content might be needed.
            const aiResult = analysisResult[index];
            return {
                id: item.id,
                riskLevel: aiResult?.riskLevel || 'low', // Default to low if AI fails for an item
                summary: aiResult?.summary || 'AI summary unavailable.',
                isLoadingRemediation: false,
            };
        });

      setRiskAnalysis(mappedAnalysis);
      toast({
        title: 'Risk Analysis Complete',
        description: 'AI has analyzed the report findings.',
      });
    } catch (err) {
      console.error('AI analysis error:', err);
      const message = err instanceof Error ? err.message : 'AI analysis failed. Please try again later.';
      setError(message);
      toast({
        title: 'Analysis Error',
        description: message,
        variant: 'destructive',
      });
      setRiskAnalysis(null);
    } finally {
      setIsAnalyzing(false);
    }
  }, [parsedReport, toast]);


 const fetchRemediation = useCallback(async (findingId: string) => {
    if (!parsedReport || !riskAnalysis) return;

    const finding = [...parsedReport.warnings, ...parsedReport.suggestions, ...parsedReport.findings].find(f => f.id === findingId);
    if (!finding) return;

    // Update state to show loading for this specific item
    setRiskAnalysis(prev =>
      prev?.map(item =>
        item.id === findingId ? { ...item, isLoadingRemediation: true } : item
      ) ?? null
    );

    try {
      const remediation = await suggestRemediation({
        finding: finding.finding,
        recommendation: finding.recommendation,
      });

      // Update state with the fetched remediation
      setRiskAnalysis(prev =>
        prev?.map(item =>
          item.id === findingId ? { ...item, remediation, isLoadingRemediation: false } : item
        ) ?? null
      );
    } catch (err) {
      console.error('Remediation suggestion error:', err);
      toast({
        title: 'Remediation Error',
        description: `Failed to get remediation for finding ${findingId}.`,
        variant: 'destructive',
      });
      // Update state to remove loading indicator on error
      setRiskAnalysis(prev =>
        prev?.map(item =>
          item.id === findingId ? { ...item, isLoadingRemediation: false } : item
        ) ?? null
      );
    }
 }, [parsedReport, riskAnalysis, toast]);


  // Trigger parsing and analysis when report content is ready
  useEffect(() => {
    if (reportContent) {
      parseReport();
    } else {
        setParsedReport(null);
        setRiskAnalysis(null);
        setError(null);
        setFileName(null);
    }
  }, [reportContent, parseReport]);

  useEffect(() => {
    if (parsedReport && !riskAnalysis && !isAnalyzing && !error) { // Only analyze if parsed, not already analyzed, not currently analyzing, and no prior error
       analyzeRisk();
    }
  }, [parsedReport, riskAnalysis, isAnalyzing, error, analyzeRisk]);


  const getRiskIcon = (level: 'high' | 'medium' | 'low') => {
    switch (level) {
      case 'high':
        return <ShieldAlert className="h-5 w-5 text-destructive" />;
      case 'medium':
        return <AlertTriangle className="h-5 w-5 text-orange-500" />;
      case 'low':
        return <ShieldCheck className="h-5 w-5 text-green-600" />;
      default:
        return <ShieldQuestion className="h-5 w-5 text-muted-foreground" />;
    }
  };

  const getRiskColor = (level: 'high' | 'medium' | 'low'): string => {
        switch (level) {
            case 'high': return 'hsl(var(--destructive))';
            case 'medium': return 'hsl(24 93% 58%)'; // orange-500 - Use HSL or Tailwind class
            case 'low': return 'hsl(142 71% 45%)'; // green-600 - Use HSL or Tailwind class
            default: return 'hsl(var(--muted-foreground))';
        }
    };

   const riskCounts = useMemo(() => {
       if (!riskAnalysis) return { high: 0, medium: 0, low: 0, total: 0 };
       const counts = riskAnalysis.reduce(
           (acc, item) => {
               acc[item.riskLevel]++;
               return acc;
           },
           { high: 0, medium: 0, low: 0 } as Record<'high' | 'medium' | 'low', number> // Type assertion for accumulator
       );
       return { ...counts, total: riskAnalysis.length };
   }, [riskAnalysis]);


  const overallStatusIcon = useMemo(() => {
        if (isLoading || isParsing || isAnalyzing) return <Loader2 className="h-6 w-6 animate-spin text-primary" />;
        if (error) return <AlertTriangle className="h-6 w-6 text-destructive" />;
        if (!parsedReport) return <FileUp className="h-6 w-6 text-muted-foreground" />; // Initial state

        switch (parsedReport.status) {
            case 'Hardened': return <ShieldCheck className="h-6 w-6 text-green-600" />;
            case 'Needs Improvement': return <AlertTriangle className="h-6 w-6 text-orange-500" />;
             case 'Vulnerable': return <ShieldAlert className="h-6 w-6 text-destructive" />;
            default: return <ShieldQuestion className="h-6 w-6 text-muted-foreground" />;
        }
    }, [isLoading, isParsing, isAnalyzing, error, parsedReport]);


  const renderFindings = (findingsToRender: LynisFinding[], title: string) => (
    <Accordion type="multiple" className="w-full">
      {findingsToRender.length > 0 ? findingsToRender.map((finding) => {
        const analysis = riskAnalysis?.find(r => r.id === finding.id);
        return (
          <AccordionItem value={finding.id} key={finding.id} className="border-b border-border last:border-b-0">
            <AccordionTrigger className="hover:bg-secondary/50 px-4 py-3 rounded-t-md transition-colors">
              <div className="flex items-center justify-between w-full">
                <div className="flex items-center gap-3 text-left flex-1 min-w-0">
                   {analysis ? (
                    <TooltipProvider delayDuration={100}>
                        <Tooltip>
                            <TooltipTrigger asChild>
                                <span className="flex-shrink-0">{getRiskIcon(analysis.riskLevel)}</span>
                            </TooltipTrigger>
                            <TooltipContent>
                                <p className="capitalize">{analysis.riskLevel} Risk</p>
                            </TooltipContent>
                        </Tooltip>
                    </TooltipProvider>
                   ) : isAnalyzing ? (
                        <Loader2 className="h-5 w-5 animate-spin text-muted-foreground flex-shrink-0" />
                   ) : (
                         <ShieldQuestion className="h-5 w-5 text-muted-foreground flex-shrink-0" />
                   )}
                  <span className="truncate font-medium">{finding.finding}</span>
                 </div>
                {/* Apply color styles directly for medium/low or use Tailwind classes if preferred */}
                {analysis && <Badge variant={analysis.riskLevel === 'high' ? 'destructive' : analysis.riskLevel === 'medium' ? 'outline' : 'secondary'} className={`ml-4 capitalize`} style={analysis.riskLevel !== 'high' ? { borderColor: getRiskColor(analysis.riskLevel), color: getRiskColor(analysis.riskLevel) } : {}}>{analysis.riskLevel}</Badge>}
              </div>
            </AccordionTrigger>
            <AccordionContent className="px-4 pt-2 pb-4 bg-secondary/30 rounded-b-md">
              <div className="space-y-3">
                <p><strong className="font-semibold text-foreground">Finding Details:</strong> {finding.finding}</p>
                <p><strong className="font-semibold text-foreground">Original Recommendation:</strong> {finding.recommendation}</p>
                 {finding.details && <p><strong className="font-semibold text-foreground">Additional Details:</strong> {finding.details}</p>}

                {analysis ? (
                    <>
                        <p><strong className="font-semibold text-foreground">AI Summary:</strong> {analysis.summary}</p>
                        {analysis.isLoadingRemediation ? (
                            <div className="flex items-center gap-2 text-muted-foreground">
                                <Loader2 className="h-4 w-4 animate-spin" />
                                <span>Loading AI Remediation...</span>
                            </div>
                        ) : analysis.remediation ? (
                            <div className="mt-3 p-3 bg-background border border-border rounded-md shadow-sm">
                                <h4 className="font-semibold mb-2 text-foreground">AI Suggested Remediation:</h4>
                                <pre className="text-sm whitespace-pre-wrap font-mono bg-muted p-2 rounded">{analysis.remediation.remediationSteps}</pre>
                            </div>
                        ) : (
                            <Button variant="link" size="sm" onClick={() => fetchRemediation(finding.id)} className="p-0 h-auto text-accent hover:underline">
                                Get AI Remediation Steps
                            </Button>
                        )}
                    </>
                ) : isAnalyzing ? (
                    <div className="flex items-center gap-2 text-muted-foreground">
                        <Loader2 className="h-4 w-4 animate-spin" />
                        <span>Analyzing Risk...</span>
                    </div>
                ) : (
                     <p className="text-muted-foreground italic">AI analysis pending or unavailable.</p>
                )}

              </div>
            </AccordionContent>
          </AccordionItem>
        );
      }) : (
          <p className="text-muted-foreground p-4 text-center">{`No ${title.toLowerCase()} found in the report.`}</p>
      )}
    </Accordion>
  );


  return (
    <div className="container mx-auto p-4 md:p-8 space-y-6">
      <header className="flex flex-col md:flex-row justify-between items-center gap-4">
        <h1 className="text-3xl font-bold text-primary">Lynis Viewer</h1>
        <label htmlFor="file-upload" className="cursor-pointer">
          <Button asChild variant="outline">
             <div>
                <FileUp className="mr-2 h-4 w-4" />
                {fileName ? `Loaded: ${fileName}` : 'Upload Lynis Report (.dat or .json)'}
             </div>
          </Button>
          <Input
            id="file-upload"
            type="file"
            accept=".dat,.json"
            onChange={handleFileChange}
            className="hidden"
            disabled={isLoading || isParsing || isAnalyzing}
          />
        </label>
      </header>

      {isLoading && (
          <Card className="animate-pulse">
              <CardHeader>
                  <Skeleton className="h-6 w-3/4" />
                   <Skeleton className="h-4 w-1/2" />
              </CardHeader>
               <CardContent>
                   <Skeleton className="h-10 w-full" />
               </CardContent>
          </Card>
      )}

        {(isParsing || isAnalyzing) && !isLoading && (
             <Card>
                 <CardHeader>
                     <CardTitle className="flex items-center gap-2">
                        <Loader2 className="h-5 w-5 animate-spin" />
                        {isParsing ? 'Parsing Report...' : 'Analyzing Risks...'}
                     </CardTitle>
                      <CardDescription>Please wait while the report is being processed.</CardDescription>
                 </CardHeader>
                 <CardContent>
                    <Progress value={(isParsing ? 33 : 66) + Math.random() * 10} className="w-full" />
                    {/* Optional: Show skeleton loaders for results */}
                 </CardContent>
            </Card>
        )}

      {error && (
        <Alert variant="destructive">
          <AlertTriangle className="h-4 w-4" />
          <AlertTitle>Error</AlertTitle>
          <AlertDescription>{error}</AlertDescription>
        </Alert>
      )}

      {!isLoading && !isParsing && !isAnalyzing && reportContent && !parsedReport && !error && (
           <Card>
               <CardHeader>
                   <CardTitle>Ready to Analyze</CardTitle>
                   <CardDescription>Report content loaded. Click the button to parse and analyze.</CardDescription>
               </CardHeader>
                <CardContent>
                    <Button onClick={parseReport} disabled={isParsing || isAnalyzing}>
                      {isParsing ? <><Loader2 className="mr-2 h-4 w-4 animate-spin" /> Parsing...</> : isAnalyzing ? <><Loader2 className="mr-2 h-4 w-4 animate-spin" /> Analyzing...</> : 'Parse and Analyze Report'}
                    </Button>
                </CardContent>
           </Card>
      )}


      {parsedReport && !error && (
        <Card className="shadow-md overflow-hidden">
            <CardHeader className="bg-secondary/50 border-b">
                 <div className="flex flex-col md:flex-row justify-between items-start md:items-center gap-4">
                    <div>
                         <CardTitle className="flex items-center gap-3 text-2xl">
                            {overallStatusIcon}
                            <span>Scan Results Overview</span>
                        </CardTitle>
                        <CardDescription className="mt-1">
                            {fileName ? `Report: ${fileName}` : 'Analysis of the uploaded Lynis report.'}
                            {parsedReport.status !== 'Unknown' && ` Overall Status: ${parsedReport.status}`}
                        </CardDescription>
                    </div>
                     {riskAnalysis && (
                        <div className="flex gap-4 items-center border p-2 rounded-md bg-background shadow-inner text-sm">
                            <div className="flex items-center gap-1" style={{ color: getRiskColor('high') }}>
                                <ShieldAlert className="h-4 w-4" /> <span className="font-semibold">{riskCounts.high} High</span>
                            </div>
                            <div className="flex items-center gap-1" style={{ color: getRiskColor('medium') }}>
                                 <AlertTriangle className="h-4 w-4" /> <span className="font-semibold">{riskCounts.medium} Medium</span>
                            </div>
                             <div className="flex items-center gap-1" style={{ color: getRiskColor('low') }}>
                                <ShieldCheck className="h-4 w-4" /> <span className="font-semibold">{riskCounts.low} Low</span>
                            </div>
                            <div className="text-muted-foreground">| Total: {riskCounts.total}</div>
                        </div>
                     )}
                 </div>
            </CardHeader>
          <CardContent className="p-0">
            <Tabs defaultValue="warnings" className="w-full">
              <TabsList className="w-full justify-start rounded-none border-b bg-card p-0">
                <TabsTrigger value="warnings" className="py-3 px-4 data-[state=active]:border-b-2 data-[state=active]:border-primary data-[state=active]:shadow-none rounded-none">Warnings ({parsedReport.warnings.length})</TabsTrigger>
                <TabsTrigger value="suggestions" className="py-3 px-4 data-[state=active]:border-b-2 data-[state=active]:border-primary data-[state=active]:shadow-none rounded-none">Suggestions ({parsedReport.suggestions.length})</TabsTrigger>
                 {/* Optionally show all findings if needed */}
                 {/* <TabsTrigger value="all" className="py-3 px-4 data-[state=active]:border-b-2 data-[state=active]:border-primary data-[state=active]:shadow-none rounded-none">All Findings ({parsedReport.findings.length})</TabsTrigger> */}
              </TabsList>

              <TabsContent value="warnings" className="p-4 md:p-6">
                 <h3 className="text-xl font-semibold mb-4 text-destructive">Warnings</h3>
                {renderFindings(parsedReport.warnings, 'Warnings')}
              </TabsContent>
              <TabsContent value="suggestions" className="p-4 md:p-6">
                  <h3 className="text-xl font-semibold mb-4" style={{ color: 'hsl(var(--primary))' }}>Suggestions</h3> {/* Use theme color */}
                 {renderFindings(parsedReport.suggestions, 'Suggestions')}
              </TabsContent>
               {/* <TabsContent value="all" className="p-4 md:p-6">
                   <h3 className="text-xl font-semibold mb-4 text-foreground">All Findings</h3>
                  {renderFindings(parsedReport.findings, 'All Findings')}
              </TabsContent> */}
            </Tabs>
          </CardContent>
        </Card>
      )}

        {!reportContent && !isLoading && !error && (
            <Card className="text-center py-12 border-dashed border-2 border-secondary hover:border-primary transition-colors duration-200">
                <CardHeader>
                    <CardTitle className="text-xl font-medium text-muted-foreground">No Report Loaded</CardTitle>
                    <CardDescription>Upload a Lynis report file (.dat or .json) using the button above to begin analysis.</CardDescription>
                </CardHeader>
                <CardContent>
                    <FileUp className="mx-auto h-12 w-12 text-muted-foreground mb-4" />
                     <label htmlFor="file-upload-cta" className="cursor-pointer">
                        <Button variant="default" size="lg" asChild>
                            <span>Select Report File</span>
                        </Button>
                         <Input
                            id="file-upload-cta"
                            type="file"
                            accept=".dat,.json"
                            onChange={handleFileChange}
                            className="hidden"
                        />
                     </label>
                </CardContent>
            </Card>
        )}
    </div>
  );
}

