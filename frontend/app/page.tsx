import Link from "next/link";
import { MessageSquare, TrendingUp, Shield, Zap } from "lucide-react";

export default function Home() {
  return (
    <div className="min-h-screen bg-gradient-to-b from-blue-50 to-white">
      {/* Header */}
      <header className="container mx-auto px-4 py-6">
        <nav className="flex justify-between items-center">
          <div className="text-2xl font-bold text-blue-600">Raisket</div>
          <div className="space-x-4">
            <Link
              href="/auth"
              className="text-gray-600 hover:text-gray-900 transition"
            >
              Iniciar Sesión
            </Link>
            <Link
              href="/auth"
              className="bg-blue-600 text-white px-6 py-2 rounded-lg hover:bg-blue-700 transition"
            >
              Empezar Gratis
            </Link>
          </div>
        </nav>
      </header>

      {/* Hero Section */}
      <main className="container mx-auto px-4 py-20">
        <div className="text-center max-w-4xl mx-auto">
          <h1 className="text-5xl md:text-6xl font-bold text-gray-900 mb-6">
            Tu Asesor Financiero{" "}
            <span className="text-blue-600">Inteligente</span>
          </h1>
          <p className="text-xl text-gray-600 mb-8">
            Toma el control de tus finanzas con ayuda de inteligencia
            artificial. Diseñado específicamente para el mercado mexicano.
          </p>
          <div className="flex gap-4 justify-center">
            <Link
              href="/auth"
              className="bg-blue-600 text-white px-8 py-4 rounded-lg text-lg font-semibold hover:bg-blue-700 transition"
            >
              Comenzar Ahora
            </Link>
            <Link
              href="/chat"
              className="border-2 border-blue-600 text-blue-600 px-8 py-4 rounded-lg text-lg font-semibold hover:bg-blue-50 transition"
            >
              Ver Demo
            </Link>
          </div>
        </div>

        {/* Features */}
        <div className="grid md:grid-cols-4 gap-8 mt-20">
          <FeatureCard
            icon={<MessageSquare className="w-8 h-8" />}
            title="Chat Inteligente"
            description="Pregunta lo que necesites sobre tus finanzas en lenguaje natural"
          />
          <FeatureCard
            icon={<TrendingUp className="w-8 h-8" />}
            title="Recomendaciones"
            description="Recibe consejos personalizados basados en tu situación"
          />
          <FeatureCard
            icon={<Shield className="w-8 h-8" />}
            title="Seguro y Confiable"
            description="Tus datos están protegidos y encriptados"
          />
          <FeatureCard
            icon={<Zap className="w-8 h-8" />}
            title="Rápido y Fácil"
            description="Empieza a mejorar tus finanzas en minutos"
          />
        </div>

        {/* CTA Section */}
        <div className="mt-20 bg-blue-600 rounded-2xl p-12 text-center text-white">
          <h2 className="text-3xl font-bold mb-4">
            ¿Listo para transformar tus finanzas?
          </h2>
          <p className="text-xl mb-8 text-blue-100">
            Únete a miles de mexicanos que ya están mejorando su salud
            financiera
          </p>
          <Link
            href="/auth"
            className="bg-white text-blue-600 px-8 py-4 rounded-lg text-lg font-semibold hover:bg-blue-50 transition inline-block"
          >
            Crear Cuenta Gratis
          </Link>
        </div>
      </main>

      {/* Footer */}
      <footer className="border-t border-gray-200 mt-20 py-8">
        <div className="container mx-auto px-4 text-center text-gray-600">
          <p>&copy; 2025 Raisket. Todos los derechos reservados.</p>
        </div>
      </footer>
    </div>
  );
}

function FeatureCard({
  icon,
  title,
  description,
}: {
  icon: React.ReactNode;
  title: string;
  description: string;
}) {
  return (
    <div className="bg-white p-6 rounded-xl shadow-sm border border-gray-100">
      <div className="text-blue-600 mb-4">{icon}</div>
      <h3 className="text-lg font-semibold mb-2">{title}</h3>
      <p className="text-gray-600">{description}</p>
    </div>
  );
}
