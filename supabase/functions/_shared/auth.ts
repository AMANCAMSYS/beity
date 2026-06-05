// @ts-ignore: VS Code's TypeScript service does not resolve Deno JSR imports; Deno/Supabase resolves this at runtime.
import "jsr:@supabase/functions-js/edge-runtime.d.ts";
// @ts-ignore: VS Code's TypeScript service does not resolve Deno JSR imports; Deno/Supabase resolves this at runtime.
import { createClient } from "jsr:@supabase/supabase-js@2";

declare const Deno: any;

export const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

export class AuthError extends Error {
  constructor(message: string, public status: number = 401) {
    super(message);
    this.name = 'AuthError';
  }
}

export const createSupabaseClient = (req: Request) => {
  const authHeader = req.headers.get('Authorization');
  if (!authHeader) {
    throw new AuthError('Missing Authorization header');
  }

  const supabaseUrl = Deno.env.get('SUPABASE_URL') ?? '';
  const supabaseAnonKey = Deno.env.get('SUPABASE_ANON_KEY') ?? '';

  return createClient(supabaseUrl, supabaseAnonKey, {
    global: { headers: { Authorization: authHeader } },
  });
};

export const requireUser = async (req: Request) => {
  const supabase = createSupabaseClient(req);
  const { data: { user }, error } = await supabase.auth.getUser();

  if (error || !user) {
    throw new AuthError('Unauthorized', 401);
  }
  return { supabase, user };
};

export const requireActiveHomeMember = async (req: Request, homeId: string) => {
  const { supabase, user } = await requireUser(req);

  const { data: membership, error } = await supabase
    .from('home_members')
    .select('role, status')
    .eq('home_id', homeId)
    .eq('user_id', user.id)
    .eq('status', 'active')
    .maybeSingle();

  if (error || !membership) {
    throw new AuthError('Forbidden: Not an active member of this home', 403);
  }

  return { supabase, user, membership };
};

export const handleOptions = (req: Request) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }
  return null;
};
